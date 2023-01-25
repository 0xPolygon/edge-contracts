import { expect } from "chai";
import { BigNumber } from "ethers";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { MerkleTree } from "merkletreejs";
import { StateReceiver, StateReceivingContract } from "../../typechain-types";
import { alwaysFalseBytecode, alwaysRevertBytecode, alwaysTrueBytecode } from "../constants";

describe("StateReceiver", () => {
  let stateReceiver: StateReceiver,
    systemStateReceiver: StateReceiver,
    stateReceivingContract: StateReceivingContract,
    revertContractAddress: string,
    increments: number[],
    stateSyncs: any[],
    tree: any,
    commitmentSize: number,
    hashes: any[];
  before(async () => {
    const StateReceiver = await ethers.getContractFactory("StateReceiver");
    stateReceiver = (await StateReceiver.deploy()) as StateReceiver;

    await stateReceiver.deployed();

    const StateReceivingContract = await ethers.getContractFactory("StateReceivingContract");
    stateReceivingContract = (await StateReceivingContract.deploy()) as StateReceivingContract;

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
    systemStateReceiver = stateReceiver.connect(systemSigner);

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);

    revertContractAddress = "0x0000000000000000000000000000000000002040";
    await hre.network.provider.send("hardhat_setCode", [revertContractAddress, alwaysRevertBytecode]);
  });

  it("State sync commit fail: no system call", async () => {
    const commitment = {
      startId: 1,
      endId: 1,
      root: ethers.constants.HashZero,
    };

    await expect(stateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero))
      .to.be.revertedWithCustomError(stateReceiver, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("State sync commit fail: invalid signature", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysFalseBytecode,
    ]);
    const commitment = {
      startId: 1,
      endId: 1,
      root: ethers.constants.HashZero,
    };
    await expect(
      systemStateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero)
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
  });

  it("State sync bad commit fail: invalid start id", async () => {
    const commitment = {
      startId: 0,
      endId: 1,
      root: ethers.constants.HashZero,
    };
    await expect(
      systemStateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero)
    ).to.be.revertedWith("INVALID_START_ID");
  });

  it("State sync bad commit fail: invalid end id", async () => {
    const commitment = {
      startId: 1,
      endId: 0,
      root: ethers.constants.HashZero,
    };
    await expect(
      systemStateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero)
    ).to.be.revertedWith("INVALID_END_ID");
  });

  it("State sync commit", async () => {
    hashes = [];
    increments = [];
    stateSyncs = [];
    commitmentSize = 2 ** randomInt(2, 3); // no. of txs per commitment
    let counter = await stateReceiver.lastCommittedId();

    for (let i = 0; i < commitmentSize; i++) {
      const increment = randomInt(1, 100);
      increments.push(increment);
      const data = ethers.utils.defaultAbiCoder.encode(["uint256"], [increment]);
      counter = counter.add(1);
      const stateSync = {
        id: counter,
        sender: ethers.constants.AddressZero,
        receiver: stateReceivingContract.address,
        data,
      };

      if (i == 1) {
        stateSync.receiver = ethers.constants.AddressZero;
      }

      stateSyncs.push(stateSync);

      const hash = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["tuple(uint id,address sender,address receiver,bytes data)"], [stateSync])
      );
      hashes.push(hash);
    }

    tree = new MerkleTree(hashes, ethers.utils.keccak256);
    const root = tree.getHexRoot();

    const commitment = {
      startId: stateSyncs[0].id,
      endId: stateSyncs[stateSyncs.length - 1].id,
      root,
    };

    const tx = await systemStateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero);

    const receipt = await tx.wait();

    const storedCommitments = await stateReceiver.commitments(0);
    expect(storedCommitments.startId).to.equal(1);
    expect(storedCommitments.endId).to.equal(counter);
    expect(storedCommitments.root).to.equal(root);
    expect(await stateReceiver.commitmentIds(0)).to.equal(counter);
    expect(await stateReceiver.lastCommittedId()).to.equal(counter);
  });

  it("State sync execute fail: invalid proof", async () => {
    expect(
      systemStateReceiver.execute([ethers.utils.hexlify(ethers.utils.randomBytes(32))], stateSyncs[0])
    ).to.be.revertedWith("INVALID_PROOF");
  });

  it("State sync execute", async () => {
    let counter = 0;
    let sum = await stateReceivingContract.counter();

    const proof = tree.getHexProof(hashes[0]);
    const tx = await stateReceiver.execute(proof, stateSyncs[0]);
    const receipt = await tx.wait();
    const logs = receipt?.events?.filter((log) => log.event === "StateSyncResult") as any[];
    expect(logs).to.exist;
    expect(logs[0]?.args?.counter).to.equal(++counter);
    sum = sum.add(increments[0]);
    expect(logs[0]?.args?.status).to.equal(true);
    expect(logs[0]?.args?.message).to.equal(sum);
  });

  it("State sync execute fail: StateSync is already processed", async () => {
    const proof = tree.getHexProof(hashes[0]);
    expect(stateReceiver.execute(proof, stateSyncs[0])).to.be.revertedWith("STATE_SYNC_IS_PROCESSED");
  });

  it("State sync batch execute fail: Length of parameters are unmatched", async () => {
    let sum = await stateReceivingContract.counter();

    let proofs = [];

    for (let i = 1; i < hashes.length; i++) {
      proofs.push(tree.getHexProof(hashes[i]));
    }

    expect(stateReceiver.batchExecute(proofs, stateSyncs)).to.be.revertedWith(
      "StateReceiver: UNMATCHED_LENGTH_PARAMETERS"
    ); //stateSyncs has 1 more array
  });

  it("State sync batch execute", async () => {
    let sum = await stateReceivingContract.counter();

    let proofs = [];

    for (let i = 1; i < hashes.length; i++) {
      proofs.push(tree.getHexProof(hashes[i]));
      sum = sum.add(increments[i]);
    }

    // Incorrect proof (function should not revert)
    proofs[1][1] = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    sum = sum.sub(increments[2]);
    // Recever code length is 0
    sum = sum.sub(increments[1]);

    const tx = await stateReceiver.batchExecute(proofs, stateSyncs.slice(1));
    const receipt = await tx.wait();
    const logs = receipt?.events?.filter((log) => log.event === "StateSyncResult") as any[];
    expect(logs).to.exist;
    expect(logs[logs.length - 1]?.args?.message).to.equal(sum);
  });

  it("State sync commit: failed message call", async () => {
    hashes = [];
    stateSyncs = [];
    let counter: BigNumber = (await stateReceiver.lastCommittedId()).add(1);

    stateSyncs = [
      {
        id: counter,
        sender: ethers.constants.AddressZero,
        receiver: revertContractAddress,
        data: ethers.constants.HashZero,
      },
    ];
    const hash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint id,address sender,address receiver,bytes data)"],
        [stateSyncs[0]]
      )
    );

    hashes.push(hash);

    tree = new MerkleTree(hashes, ethers.utils.keccak256);

    const root = tree.getHexRoot();

    const commitment = {
      startId: stateSyncs[0].id,
      endId: stateSyncs[stateSyncs.length - 1].id,
      root,
    };
    await expect(systemStateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero)).to.not.be
      .reverted;
  });

  it("State sync execute: failed message call", async () => {
    let counter: BigNumber = await stateReceiver.lastCommittedId();
    const proof = tree.getHexProof(hashes[0]);
    const tx = await systemStateReceiver.execute(proof, stateSyncs[0]);
    const receipt = await tx.wait();
    const logs = receipt?.events?.filter((log) => log.event === "StateSyncResult") as any[];
    expect(logs).to.exist;
    expect(logs[0]?.args?.counter).to.equal(counter);
    expect(logs[0]?.args?.status).to.equal(false);
    expect(logs[0]?.args?.message).to.equal("0x");
  });

  it("State sync bad commit", async () => {
    hashes = [];
    stateSyncs = [];
    let counter: BigNumber = (await stateReceiver.lastCommittedId()).add(1);
    stateSyncs = [
      {
        id: counter,
        sender: ethers.constants.AddressZero,
        receiver: revertContractAddress,
        data: ethers.constants.HashZero,
      },
      {
        id: counter.add(2),
        sender: ethers.constants.AddressZero,
        receiver: revertContractAddress,
        data: ethers.constants.HashZero,
      },
    ];

    const hash1 = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint id,address sender,address receiver,bytes data)"],
        [stateSyncs[0]]
      )
    );
    hashes.push(hash1);
    const hash2 = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint id,address sender,address receiver,bytes data)"],
        [stateSyncs[1]]
      )
    );
    hashes.push(hash2);

    tree = new MerkleTree(hashes, ethers.utils.keccak256);

    const root = tree.getHexRoot();

    const commitment = {
      startId: stateSyncs[0].id,
      endId: stateSyncs[stateSyncs.length - 1].id,
      root,
    };
    const tx = await systemStateReceiver.commit(commitment, ethers.constants.HashZero, ethers.constants.HashZero);

    await tx.wait();
  });

  /*it("State sync bad commit execute fail: non-sequential id", async () => {
    let stateSyncCounter: BigNumber = (await stateReceiver.lastCommittedId()).add(2);
    const proof = tree.getHexProof(hashes[0]);
    await expect(systemStateReceiver.execute(proof, stateSyncs[0])).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });*/

  it("Get root", async () => {
    const expectedRoot = (await systemStateReceiver.commitments(0)).root;
    expect(await systemStateReceiver.getRootByStateSyncId(2)).to.equal(expectedRoot);
  });

  it("Get root revert", async () => {
    await expect(systemStateReceiver.getRootByStateSyncId(999)).to.be.revertedWith("StateReceiver: NO_ROOT_FOR_ID");
  });

  it("Get commitment by stateSynd id revert", async () => {
    await expect(systemStateReceiver.getCommitmentByStateSyncId(100)).to.be.revertedWith(
      "StateReceiver: NO_COMMITMENT_FOR_ID"
    );
  });
});

function randomInt(min: number, max: number) {
  // min and max included
  return Math.floor(Math.random() * (max - min + 1) + min);
}
