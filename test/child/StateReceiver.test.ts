import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { FakeContract, smock } from "@defi-wonderland/smock";
import { StateReceiver, StateReceivingContract } from "../../typechain";

describe("StateReceiver", () => {
  let stateReceiver: StateReceiver,
    systemStateReceiver: StateReceiver,
    stateReceivingContract: StateReceivingContract,
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
      "0x600160005260206000F3",
    ]);
  });
  it("State sync without system call", async () => {
    await expect(stateReceiver.stateSyncBatch([], [])).to.be.revertedWith(
      "ONLY_SYSTEMCALL"
    );
  });
  it("Empty state sync batch", async () => {
    await expect(systemStateReceiver.stateSyncBatch([], [])).to.be.revertedWith(
      "NO_STATESYNC_DATA"
    );
  });
  it("State sync", async () => {
    const increment = Math.floor(Math.random() * (10 - 1) + 1);
    const data = ethers.utils.defaultAbiCoder.encode(["uint256"], [increment]);
    const stateSync = {
      id: 1,
      sender: ethers.constants.AddressZero,
      receiver: stateReceivingContract.address,
      data,
      skip: false,
    };
    await systemStateReceiver.stateSync(stateSync, ethers.constants.HashZero);
    expect(await stateReceiver.counter()).to.equal(1);
    expect(await stateReceivingContract.counter()).to.equal(increment);
  });
  it("State sync batch", async () => {
    let currentSum = await stateReceivingContract.counter();
    const stateSyncs: any[] = [];
    const batchSize = Math.floor(Math.random() * (10 - 2) + 2);
    for (let i = 1; i <= batchSize; i++) {
      const increment = Math.floor(Math.random() * (10 - 1) + 1);
      currentSum = currentSum.add(BigNumber.from(increment));
      const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256"],
        [increment]
      );
      const stateSync = {
        id: i + 1,
        sender: ethers.constants.AddressZero,
        receiver: stateReceivingContract.address,
        data,
        skip: false,
      };
      stateSyncs.push(stateSync);
    }
    await systemStateReceiver.stateSyncBatch(
      stateSyncs,
      ethers.constants.HashZero
    );
    expect(await stateReceiver.counter()).to.equal(batchSize + 1);
    expect(await stateReceivingContract.counter()).to.equal(currentSum);
  });
});
