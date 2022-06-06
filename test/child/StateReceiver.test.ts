import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { FakeContract, smock } from "@defi-wonderland/smock";
import { StateReceiver, StateReceivingContract } from "../../typechain";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";

import { MerkleTree } from "merkletreejs";
import { keccak256 } from "keccak256";
import { SHA256 } from "crypto-js/sha256";

describe("StateReceiver", () => {
  let stateReceiver: StateReceiver,
    systemStateReceiver: StateReceiver,
    stateReceivingContract: StateReceivingContract,
    stateSyncCounter: number,
    batchSize: number,
    tree: any,
    hashes: any[],
    stateSyncBundle: any[],
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
    const bundleSize = 128;
    batchSize = 2;
    hashes = [];
    stateSyncBundle = [];
    for (let j = 0; j < bundleSize; j++) {
      const stateSyncs = [];
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
      stateSyncBundle.push(stateSyncs);
      const hash = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          [
            "tuple(uint id,address sender,address receiver,bytes data,bool skip)[]",
          ],
          [stateSyncs]
        )
      );
      hashes.push(hash);
    }

    console.log(hashes);

    tree = new MerkleTree(hashes, ethers.utils.keccak256);
    const root = tree.getHexRoot();
    console.log(tree.toString());

    const bundle = {
      startId: 0,
      endId: batchSize * bundleSize - 1,
      leaves: bundleSize,
      root,
    };
    const tx = await systemStateReceiver.commit(
      bundle,
      ethers.constants.HashZero
    );
    const receipt = await tx.wait();
    console.log(receipt);
  });
  it("State sync execute", async () => {
    let currentSum = await stateReceivingContract.counter();
    let i = 0;
    for (const stateSyncs of stateSyncBundle) {
      const proof = tree.getHexProof(hashes[i++]);
      console.log(proof);
      const tx = await systemStateReceiver.execute(proof, stateSyncs);
      const receipt = await tx.wait();
      console.log(receipt.cumulativeGasUsed);
      const log = receipt?.events as any[];
      for (let i = 1; i <= batchSize; i++) {
        const stateSync = stateSyncs[i];
        expect(log[i]?.args?.counter).to.equal(i + 1);
        expect(log[i]?.args?.status).to.equal(1);
      }
      expect(await stateReceiver.counter()).to.equal(batchSize + 1);
      expect(await stateReceivingContract.counter()).to.equal(currentSum);
      const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256"],
        [await stateReceivingContract.counter()]
      );
      expect(log[batchSize - 1]?.args?.message).to.equal(data);
    }
  });
});
