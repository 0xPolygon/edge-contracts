import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { FakeContract, smock } from "@defi-wonderland/smock";
import { StateReceiver, StateReceivingContract } from "../../typechain";
import { alwaysTrueBytecode, alwaysFalseBytecode, alwaysRevertBytecode } from "../constants";
import { customError } from "../util";
import { MerkleTree } from "merkletreejs";

describe("StateReceiver", () => {
  let stateReceiver: StateReceiver,
    systemStateReceiver: StateReceiver,
    stateReceivingContract: StateReceivingContract,
    stateSyncCounter: BigNumber,
    bundleSize: number,
    batchSize: number,
    revertContractAddress: string,
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

    revertContractAddress = "0x0000000000000000000000000000000000002040";
    await hre.network.provider.send("hardhat_setCode", [revertContractAddress, alwaysRevertBytecode]);
  });

  it("State sync commit fail: no system call", async () => {
    const bundle = {
      startId: 1,
      endId: 1,
      leaves: 1,
      root: ethers.constants.HashZero,
    };

    await expect(stateReceiver.commit(bundle, ethers.constants.HashZero, [])).to.be.revertedWith(
      customError("Unauthorized", "SYSTEMCALL")
    );
  });

  it("State sync commit fail: invalid signature", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysFalseBytecode,
    ]);
    const bundle = {
      startId: 1,
      endId: 1,
      leaves: 1,
      root: ethers.constants.HashZero,
    };
    await expect(systemStateReceiver.commit(bundle, ethers.constants.HashZero, [])).to.be.revertedWith(
      "SIGNATURE_VERIFICATION_FAILED"
    );
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
  });

  it("State sync bad commit fail: invalid start id", async () => {
    const bundle = {
      startId: 0,
      endId: 1,
      leaves: 1,
      root: ethers.constants.HashZero,
    };
    await expect(systemStateReceiver.commit(bundle, ethers.constants.HashZero, [])).to.be.revertedWith(
      "INVALID_START_ID"
    );
  });

  it("State sync bad commit fail: invalid end id", async () => {
    const bundle = {
      startId: 1,
      endId: 0,
      leaves: 1,
      root: ethers.constants.HashZero,
    };
    await expect(systemStateReceiver.commit(bundle, ethers.constants.HashZero, [])).to.be.revertedWith(
      "INVALID_END_ID"
    );
  });

  it("State sync commit", async () => {
    currentSum = BigNumber.from(0);
    bundleSize = Math.floor(Math.random() * 5 + 1); // no. of txs per bundle
    batchSize = 2 ** Math.floor(Math.random() + 2); // number of bundles
    hashes = [];
    stateSyncBundle = [];
    stateSyncCounter = await stateReceiver.counter();
    let counter: number = 1;
    for (let j = 0; j < batchSize; j++) {
      const stateSyncs = [];
      stateSyncCounter = stateSyncCounter.add(bundleSize);
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
      startId: 1,
      endId: batchSize * bundleSize,
      leaves: batchSize,
      root,
    };
    const tx = await systemStateReceiver.commit(bundle, ethers.constants.HashZero, []);

    const receipt = await tx.wait();
  });

  it("State sync check last committed id: yet to execute", async () => {
    expect(await stateReceiver.lastCommittedId()).to.equal(stateSyncCounter);
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

  it("State sync check last committed id: all executed", async () => {
    expect(await stateReceiver.lastCommittedId()).to.equal(await stateReceiver.counter());
  });

  it("State sync commit: skipped", async () => {
    hashes = [];
    stateSyncBundle = [];
    let counter: BigNumber = (await stateReceiver.counter()).add(1);
    const stateSyncs = [
      {
        id: counter,
        sender: ethers.constants.AddressZero,
        receiver: stateReceivingContract.address,
        data: ethers.constants.HashZero,
        skip: true,
      },
    ];
    stateSyncBundle.push(stateSyncs);
    const hash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint id,address sender,address receiver,bytes data,bool skip)[]"],
        [stateSyncs]
      )
    );
    hashes.push(hash);

    tree = new MerkleTree(hashes, ethers.utils.keccak256);

    const root = tree.getHexRoot();

    const bundle = {
      startId: counter,
      endId: counter,
      leaves: 1,
      root,
    };
    await expect(systemStateReceiver.commit(bundle, ethers.constants.HashZero, [])).to.not.be.reverted;
  });

  it("State sync execute: skipped", async () => {
    let stateSyncCounter: BigNumber = (await stateReceiver.counter()).add(1);
    const proof = tree.getHexProof(hashes[0]);
    const stateSyncs = stateSyncBundle[0];
    const tx = await systemStateReceiver.execute(proof, stateSyncs);
    const receipt = await tx.wait();
    const logs = receipt?.events?.filter((log) => log.event === "StateSyncResult") as any[];
    expect(logs).to.exist;
    expect(logs[0]?.args?.counter).to.equal(stateSyncCounter);
    expect(logs[0]?.args?.status).to.equal(2);
    expect(await stateReceiver.counter()).to.equal(stateSyncCounter);
  });

  it("State sync commit: failed message call", async () => {
    hashes = [];
    stateSyncBundle = [];
    let counter: BigNumber = (await stateReceiver.counter()).add(1);
    const stateSyncs = [
      {
        id: counter,
        sender: ethers.constants.AddressZero,
        receiver: revertContractAddress,
        data: ethers.constants.HashZero,
        skip: false,
      },
    ];
    stateSyncBundle.push(stateSyncs);
    const hash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint id,address sender,address receiver,bytes data,bool skip)[]"],
        [stateSyncs]
      )
    );

    hashes.push(hash);

    tree = new MerkleTree(hashes, ethers.utils.keccak256);

    const root = tree.getHexRoot();

    const bundle = {
      startId: counter,
      endId: counter,
      leaves: 1,
      root,
    };
    await expect(systemStateReceiver.commit(bundle, ethers.constants.HashZero, [])).to.not.be.reverted;
  });

  it("State sync execute: failed message call", async () => {
    let stateSyncCounter: BigNumber = (await stateReceiver.counter()).add(1);
    const proof = tree.getHexProof(hashes[0]);
    const stateSyncs = stateSyncBundle[0];
    const tx = await systemStateReceiver.execute(proof, stateSyncs);
    const receipt = await tx.wait();
    const logs = receipt?.events?.filter((log) => log.event === "StateSyncResult") as any[];
    expect(logs).to.exist;
    expect(logs[0]?.args?.counter).to.equal(stateSyncCounter);
    expect(logs[0]?.args?.status).to.equal(1);
    expect(logs[0]?.args?.message).to.equal(ethers.constants.HashZero);
    expect(await stateReceiver.counter()).to.equal(stateSyncCounter);
  });

  it("State sync execute fail: nothing to execute", async () => {
    await expect(systemStateReceiver.execute([], [])).to.be.revertedWith("NOTHING_TO_EXECUTE");
  });

  it("State sync bad commit", async () => {
    hashes = [];
    stateSyncBundle = [];
    let counter: BigNumber = (await stateReceiver.counter()).add(1);
    const stateSyncs = [
      {
        id: counter,
        sender: ethers.constants.AddressZero,
        receiver: revertContractAddress,
        data: ethers.constants.HashZero,
        skip: false,
      },
      {
        id: counter.add(2),
        sender: ethers.constants.AddressZero,
        receiver: revertContractAddress,
        data: ethers.constants.HashZero,
        skip: false,
      },
    ];
    stateSyncBundle.push(stateSyncs);
    const hash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint id,address sender,address receiver,bytes data,bool skip)[]"],
        [stateSyncs]
      )
    );

    hashes.push(hash);

    tree = new MerkleTree(hashes, ethers.utils.keccak256);

    const root = tree.getHexRoot();

    const bundle = {
      startId: counter,
      endId: counter,
      leaves: 1,
      root,
    };
    const tx = await systemStateReceiver.commit(bundle, ethers.constants.HashZero, []);

    await tx.wait();
  });

  it("State sync bad commit execute fail: non-sequential id", async () => {
    let stateSyncCounter: BigNumber = (await stateReceiver.counter()).add(2);
    const proof = tree.getHexProof(hashes[0]);
    const stateSyncs = stateSyncBundle[0];
    await expect(systemStateReceiver.execute(proof, stateSyncs, [])).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });
});
