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
  it("State sync without system call", async () => {
    const stateSync = {
      id: 0,
      sender: ethers.constants.AddressZero,
      receiver: ethers.constants.AddressZero,
      data: ethers.constants.HashZero,
      skip: false,
    };
    await expect(stateReceiver.stateSync(stateSync, [])).to.be.revertedWith(
      "ONLY_SYSTEMCALL"
    );
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
    stateSyncCounter = 1;
    const stateSync = {
      id: 1,
      sender: ethers.constants.AddressZero,
      receiver: stateReceivingContract.address,
      data,
      skip: false,
    };
    const tx = await systemStateReceiver.stateSync(
      stateSync,
      ethers.constants.HashZero
    );
    const receipt = await tx.wait();
    const log = receipt?.events as any[];
    expect(log[0]?.args?.counter).to.equal(1);
    expect(log[0]?.args?.status).to.equal(0);
    expect(log[0]?.args?.message).to.equal("0x");
    expect(await stateReceiver.counter()).to.equal(1);
    expect(await stateReceivingContract.counter()).to.equal(increment);
  });
  it("State sync batch", async () => {
    let currentSum = await stateReceivingContract.counter();
    const stateSyncs: any[] = [];
    const batchSize = Math.floor(Math.random() * (10 - 2) + 2);
    stateSyncCounter += batchSize;
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
    const tx = await systemStateReceiver.stateSyncBatch(
      stateSyncs,
      ethers.constants.HashZero
    );
    const receipt = await tx.wait();
    const log = receipt?.events as any[];
    for (let i = 0; i < batchSize; i++) {
      const stateSync = stateSyncs[i];
      expect(log[i]?.args?.counter).to.equal(i + 2);
      expect(log[i]?.args?.status).to.equal(0);
      expect(log[i]?.args?.message).to.equal("0x");
    }
    expect(await stateReceiver.counter()).to.equal(stateSyncCounter);
    expect(await stateReceivingContract.counter()).to.equal(currentSum);
  });
  it("State sync skip", async () => {
    stateSyncCounter += 1;
    const stateSync = {
      id: stateSyncCounter,
      sender: ethers.constants.AddressZero,
      receiver: stateReceivingContract.address,
      data: ethers.constants.HashZero,
      skip: true,
    };
    const tx = await systemStateReceiver.stateSync(
      stateSync,
      ethers.constants.HashZero
    );
    const receipt = await tx.wait();
    const log = receipt?.events as any[];
    expect(log[0]?.args?.counter).to.equal(stateSyncCounter);
    expect(log[0]?.args?.status).to.equal(2);
    expect(log[0]?.args?.message).to.equal("0x");
  });
  it("State sync fail", async () => {
    stateSyncCounter += 1;
    const fakeStateReceivingContract = await smock.fake(
      "StateReceivingContract"
    );
    fakeStateReceivingContract.onStateReceive.reverts();
    const stateSync = {
      id: stateSyncCounter,
      sender: ethers.constants.AddressZero,
      receiver: fakeStateReceivingContract.address,
      data: ethers.constants.HashZero,
      skip: false,
    };
    const tx = await systemStateReceiver.stateSync(
      stateSync,
      ethers.constants.HashZero
    );
    const receipt = await tx.wait();
    const log = receipt?.events as any[];
    expect(log[0]?.args?.counter).to.equal(stateSyncCounter);
    expect(log[0]?.args?.status).to.equal(1);
    expect(log[0]?.args?.message).to.equal("0x");
  });
  it("State sync bad signature", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysFalseBytecode,
    ]);
    const stateSync = {
      id: 0,
      sender: ethers.constants.AddressZero,
      receiver: ethers.constants.AddressZero,
      data: ethers.constants.HashZero,
      skip: false,
    };
    await expect(
      systemStateReceiver.stateSync(stateSync, ethers.constants.HashZero)
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });
});
