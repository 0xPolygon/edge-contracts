import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { FakeContract, smock } from "@defi-wonderland/smock";
import { StateReceiver, StateReceivingContract } from "../../typechain";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";

describe("StateReceiver", () => {
  let stateReceiver: StateReceiver,
    systemStateReceiver: StateReceiver,
    stateReceivingContract: StateReceivingContract,
    stateSyncCounter: number,
    stateSyncs: any[],
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    accounts = await ethers.getSigners();
    const StateReceiver = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    const StateReceivingContract = await ethers.getContractFactory(
      "StateReceivingContract"
    );
    stateReceivingContract = await StateReceivingContract.deploy();

    await stateReceivingContract.deployed();

    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      "0x0000000000000000000000000000000000001001",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });
    const systemSigner = await ethers.getSigner(
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"
    );
    systemStateReceiver = await stateReceiver.connect(systemSigner);

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
  });
  it("State sync commit", async () => {
    let currentSum = await stateReceivingContract.counter();
    const batchSize = 277;
    // 299 executed
    // 359 calldata limit
    stateSyncs = [];
    stateSyncCounter += batchSize;
    for (let i = 1; i <= batchSize; i++) {
      const increment = Math.floor(Math.random() * (10 - 1) + 1);
      currentSum = currentSum.add(BigNumber.from(increment));
      const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256"],
        [increment]
      );
      const stateSync = {
        id: i,
        sender: ethers.constants.AddressZero,
        receiver: stateReceivingContract.address,
        data,
        skip: false,
      };
      stateSyncs.push(stateSync);
    }
    const hash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "tuple(uint id,address sender,address receiver,bytes data,bool skip)[]",
        ],
        [stateSyncs]
      )
    );
    console.log(hash);
    const bundle = {
      startId: 0,
      endId: batchSize - 1,
      hash,
    };
    const tx = await systemStateReceiver.commit(
      bundle,
      ethers.constants.HashZero
    );
    const receipt = await tx.wait();
    console.log(tx);
  });
  it("State sync execute", async () => {
    let currentSum = await stateReceivingContract.counter();
    //console.log(stateSyncs);
    const tx = await systemStateReceiver.execute(stateSyncs);
    const receipt = await tx.wait();
    console.log(tx);
    const log = receipt?.events as any[];
    for (let i = 0; i < batchSize; i++) {
      const stateSync = stateSyncs[i];
      expect(log[i]?.args?.counter).to.equal(i + 2);
      expect(log[i]?.args?.status).to.equal(0);
    }
    expect(await stateReceiver.counter()).to.equal(stateSyncCounter);
    expect(await stateReceivingContract.counter()).to.equal(currentSum);
    const data = ethers.utils.defaultAbiCoder.encode(
      ["uint256"],
      [await stateReceivingContract.counter()]
    );
    //expect(log[batchSize - 1]?.args?.message).to.equal(data);
  });
});
