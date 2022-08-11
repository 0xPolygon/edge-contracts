import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { FakeContract, smock } from "@defi-wonderland/smock";
import { StateReceiver, StateReceivingContract } from "../../typechain";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";
import { customError } from "../util";
import { MerkleTree } from "merkletreejs";

describe("StateReceiver", () => {
  let stateReceiver: StateReceiver,
    systemStateReceiver: StateReceiver,
    stateReceivingContract: StateReceivingContract,
    stateSyncCounter: number,
    bundleSize: number,
    batchSize: number,
    currentSum: BigNumber,
    tree: any,
    hashes: any[],
    stateSyncBundle: any[],
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    accounts = await ethers.getSigners();
    const StateReceiver = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    const StateReceivingContract = await ethers.getContractFactory("StateReceivingContract");
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
    const systemSigner = await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    systemStateReceiver = await stateReceiver.connect(systemSigner);

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
  });

  it("State sync commit fail: no system call", async () => {
    const bundle = {
      startId: 0,
      endId: 1,
      leaves: 1,
      root: ethers.constants.HashZero,
    };

    await expect(stateReceiver.commit(bundle, ethers.constants.HashZero)).to.be.revertedWith(
      customError("Unauthorized", "SYSTEMCALL")
    );
  });

  it("State sync commit fail: invalid signature", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysFalseBytecode,
    ]);
    const bundle = {
      startId: 0,
      endId: 1,
      leaves: 1,
      root: ethers.constants.HashZero,
    };
    await expect(systemStateReceiver.commit(bundle, ethers.constants.HashZero)).to.be.revertedWith(
      "SIGNATURE_VERIFICATION_FAILED"
    );
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
  });

  it("State sync commit", async () => {
    currentSum = BigNumber.from(0);
    bundleSize = Math.floor(Math.random() * 5 + 1);
    batchSize = 2 ** Math.floor(Math.random() * 1 + 2);
    hashes = [];
    stateSyncBundle = [];
    stateSyncCounter = 0;
    let counter: number = 1;
    for (let j = 0; j < batchSize; j++) {
      const stateSyncs = [];
      stateSyncCounter += batchSize;
      for (let i = 0; i < bundleSize; i++) {
        const increment = Math.floor(Math.random() * 9 + 1);
        currentSum = currentSum.add(BigNumber.from(increment));
        const data = ethers.utils.defaultAbiCoder.encode(["uint256"], [increment]);
        const stateSync = {
          id: counter++,
          sender: ethers.constants.AddressZero,
          receiver: stateReceivingContract.address,
          data,
          skip: false,
        };
        stateSyncs.push(stateSync);
      }
      stateSyncBundle.push(stateSyncs);
      const hash = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["tuple(uint id,address sender,address receiver,bytes data,bool skip)[]"],
          [stateSyncs]
        )
      );
      hashes.push(hash);
    }

    tree = new MerkleTree(hashes, ethers.utils.keccak256);

    const root = tree.getHexRoot();

    const bundle = {
      startId: 0,
      endId: batchSize * bundleSize - 1,
      leaves: batchSize,
      root,
    };
    const tx = await systemStateReceiver.commit(bundle, ethers.constants.HashZero);

    const receipt = await tx.wait();
  });

  it("State sync execute fail: invalid proof", async () => {
    await expect(systemStateReceiver.execute([ethers.utils.hexlify(ethers.utils.randomBytes(32))], stateSyncBundle[0]))
      .to.be.reverted; // this is because either the library will revert or the contract will
  });

  it("State sync execute", async () => {
    let bundleCounter: number = 0;
    let stateSyncCounter: number = 1;
    for (const stateSyncs of stateSyncBundle) {
      const proof = tree.getHexProof(hashes[bundleCounter++]);
      const tx = await systemStateReceiver.execute(proof, stateSyncs);
      const receipt = await tx.wait();
      const logs = receipt?.events?.filter((log) => log.event === "StateSyncResult") as any[];
      expect(logs).to.exist;
      for (let i = 0; i < bundleSize; i++) {
        const stateSync = stateSyncs[i];
        expect(logs[i]?.args?.counter).to.equal(stateSyncCounter++);
        expect(logs[i]?.args?.status).to.equal(0);
      }
      expect(await stateReceiver.counter()).to.equal(stateSyncCounter - 1);
    }
    expect(await stateReceivingContract.counter()).to.equal(currentSum);
  });
});
