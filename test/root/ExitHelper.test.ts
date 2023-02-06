import { expect } from "chai";
import { ethers } from "hardhat";
import { MerkleTree } from "merkletreejs";
import * as mcl from "../../ts/mcl";
import { BLS, BN256G2, CheckpointManager, ExitHelper } from "../../typechain-types";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_CHECKPOINT_MANAGER"]));

describe("ExitHelper", () => {
  let bls: BLS,
    bn256G2: BN256G2,
    governance: string,
    checkpointManager: CheckpointManager,
    exitHelper: ExitHelper,
    submitCounter: number,
    startBlock: number,
    validatorSetSize: number,
    validatorSecretKeys: any[],
    validatorSet: any[],
    leaves: any[],
    tree: MerkleTree,
    accounts: any[]; // we use any so we can access address directly from object
  const chainId = 12345;
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const BLS = await ethers.getContractFactory("BLS");
    bls = (await BLS.deploy()) as BLS;
    await bls.deployed();

    const BN256G2 = await ethers.getContractFactory("BN256G2");
    bn256G2 = (await BN256G2.deploy()) as BN256G2;
    await bn256G2.deployed();

    const CheckpointManager = await ethers.getContractFactory("CheckpointManager");
    checkpointManager = (await CheckpointManager.deploy()) as CheckpointManager;
    await checkpointManager.deployed();

    const ExitHelper = await ethers.getContractFactory("ExitHelper");
    exitHelper = (await ExitHelper.deploy()) as ExitHelper;
    await exitHelper.deployed();
  });

  it("Initialize CheckpointManager and validate initialization", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12

    validatorSecretKeys = [];
    validatorSet = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      validatorSecretKeys.push(secret);
      validatorSet.push({
        _address: accounts[i].address,
        blsKey: mcl.g2ToHex(pubkey),
        votingPower: ethers.utils.parseEther(((i + 1) * 2).toString()),
      });
    }

    await checkpointManager.initialize(bls.address, bn256G2.address, chainId, validatorSet);
    expect(await checkpointManager.bls()).to.equal(bls.address);
    expect(await checkpointManager.bn256G2()).to.equal(bn256G2.address);
    expect(await checkpointManager.currentValidatorSetLength()).to.equal(validatorSetSize);

    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await checkpointManager.currentValidatorSet(i);
      expect(validator._address).to.equal(accounts[i].address);
      expect(validator.votingPower).to.equal(ethers.utils.parseEther(((i + 1) * 2).toString()));
    }

    const endBlock = (await checkpointManager.checkpoints(0)).blockNumber;
    expect(endBlock).to.equal(0);
    startBlock = endBlock.toNumber() + 1;
    const prevId = await checkpointManager.currentEpoch();
    submitCounter = prevId.toNumber() + 1;
  });

  it("Initialize ExitHelp failed by invalid address", async () => {
    await expect(exitHelper.initialize("0x0000000000000000000000000000000000000000")).to.be.revertedWith(
      "ExitHelper: INVALID_ADDRESS"
    );
  });

  it("Exit failed by uninitialized", async () => {
    const blockNumber = 0;
    const leafIndex = 0;
    const unhashedLeaf = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

    await expect(exitHelper.exit(blockNumber, leafIndex, unhashedLeaf, proof)).to.be.revertedWith(
      "ExitHelper: NOT_INITIALIZED"
    );
  });

  it("BatchExit failed by uninitialized", async () => {
    const blockNumber = 0;
    const leafIndex = 0;
    const unhashedLeaf = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

    const batchExitInput = {
      blockNumber,
      leafIndex,
      unhashedLeaf,
      proof,
    };

    await expect(exitHelper.batchExit([batchExitInput])).to.be.revertedWith("ExitHelper: NOT_INITIALIZED");
  });

  it("Initialize ExitHelp and validate initialization", async () => {
    await exitHelper.initialize(checkpointManager.address);
    expect(await exitHelper.checkpointManager()).to.equal(checkpointManager.address);
  });

  it("Exit success", async () => {
    const id = 0;
    const sender = accounts[0].address;
    const receiver = accounts[1].address;
    const data = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const unhashedLeaf = ethers.utils.defaultAbiCoder.encode(
      ["uint", "address", "address", "bytes"],
      [id, sender, receiver, data]
    );

    const leaves = [
      ethers.utils.keccak256(unhashedLeaf),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];
    const tree = new MerkleTree(leaves, ethers.utils.keccak256);

    //----------------- Checkpoint Submit --------------------
    const checkpoint = {
      epoch: 1,
      blockNumber: 1,
      eventRoot: tree.getHexRoot(),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSetHash: await checkpointManager.currentValidatorSetHash(),
    };

    const bitmap = "0xffff";
    const messageOfValidatorSet = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
        [validatorSet]
      )
    );

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "bytes32", "uint256", "uint256", "bytes32", "bytes32", "bytes32"],
        [
          chainId,
          checkpoint.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint.epoch,
          checkpoint.eventRoot,
          checkpointMetadata.currentValidatorSetHash,
          messageOfValidatorSet,
        ]
      )
    );

    const signatures: mcl.Signature[] = [];

    let aggVotingPower = 0;
    for (let i = 0; i < validatorSecretKeys.length; i++) {
      const byteNumber = Math.floor(i / 8);
      const bitNumber = i % 8;

      if (byteNumber >= bitmap.length / 2 - 1) {
        continue;
      }

      // Get the value of the bit at the given 'index' in a byte.
      const oneByte = parseInt(bitmap[2 + byteNumber * 2] + bitmap[3 + byteNumber * 2], 16);
      if ((oneByte & (1 << bitNumber)) > 0) {
        const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures.push(signature);
        aggVotingPower += parseInt(validatorSet[i].votingPower, 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSet, bitmap);

    expect(await checkpointManager.getEventRootByBlock(checkpoint.blockNumber)).to.equal(checkpoint.eventRoot);
    expect(await checkpointManager.checkpointBlockNumbers(0)).to.equal(checkpoint.blockNumber);

    const leafIndex = 0;

    const proof = tree.getHexProof(leaves[leafIndex]);

    expect(
      await checkpointManager.getEventMembershipByBlockNumber(
        checkpoint.blockNumber,
        leaves[leafIndex],
        leafIndex,
        proof
      )
    ).to.equal(true);
    //----------------- Checkpoint Submit --------------------

    expect(await exitHelper.processedExits(id)).to.equal(false);
    const tx = await exitHelper.exit(checkpoint.blockNumber, leafIndex, unhashedLeaf, proof);

    await expect(tx).to.emit(exitHelper, "ExitProcessed");
    expect(await exitHelper.processedExits(id)).to.equal(true);
  });

  it("Exit failed by invalid proof", async () => {
    const blockNumber = 1;
    const leafIndex = 0;

    const id = 1;
    const sender = accounts[0].address;
    const receiver = accounts[1].address;
    const data = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const unhashedLeaf = ethers.utils.defaultAbiCoder.encode(
      ["uint", "address", "address", "bytes"],
      [id, sender, receiver, data]
    );
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

    await expect(exitHelper.exit(blockNumber, leafIndex, unhashedLeaf, proof)).to.be.revertedWith(
      "ExitHelper: INVALID_PROOF"
    );
  });

  it("Exit failed by already processed", async () => {
    const blockNumber = 0;
    const leafIndex = 0;

    const id = 0;
    const sender = accounts[0].address;
    const receiver = accounts[1].address;
    const data = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const unhashedLeaf = ethers.utils.defaultAbiCoder.encode(
      ["uint", "address", "address", "bytes"],
      [id, sender, receiver, data]
    );
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

    await expect(exitHelper.exit(blockNumber, leafIndex, unhashedLeaf, proof)).to.be.revertedWith(
      "ExitHelper: EXIT_ALREADY_PROCESSED"
    );
  });

  it("BatchExit success", async () => {
    const id = 1;
    const sender = accounts[0].address;
    const receiver = accounts[1].address;
    const data = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const unhashedLeaf1 = ethers.utils.defaultAbiCoder.encode(
      ["uint", "address", "address", "bytes"],
      [id, sender, receiver, data]
    );

    const unhashedLeaf2 = ethers.utils.defaultAbiCoder.encode(
      ["uint", "address", "address", "bytes"],
      [id + 1, sender, receiver, data]
    );

    const leaves = [
      ethers.utils.keccak256(unhashedLeaf1),
      ethers.utils.keccak256(unhashedLeaf2),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];
    const tree = new MerkleTree(leaves, ethers.utils.keccak256);

    //----------------- Checkpoint Submit --------------------
    const checkpoint1 = {
      epoch: 2,
      blockNumber: 2,
      eventRoot: tree.getHexRoot(),
    };

    const checkpoint2 = {
      epoch: 3,
      blockNumber: 3,
      eventRoot: tree.getHexRoot(),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSetHash: await checkpointManager.currentValidatorSetHash(),
    };

    const bitmap = "0xffff";
    const messageOfValidatorSet = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
        [validatorSet]
      )
    );

    const message1 = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "bytes32", "uint256", "uint256", "bytes32", "bytes32", "bytes32"],
        [
          chainId,
          checkpoint1.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint1.epoch,
          checkpoint1.eventRoot,
          checkpointMetadata.currentValidatorSetHash,
          messageOfValidatorSet,
        ]
      )
    );

    const signatures1: mcl.Signature[] = [];

    let aggVotingPower = 0;
    for (let i = 0; i < validatorSecretKeys.length; i++) {
      const byteNumber = Math.floor(i / 8);
      const bitNumber = i % 8;

      if (byteNumber >= bitmap.length / 2 - 1) {
        continue;
      }

      // Get the value of the bit at the given 'index' in a byte.
      const oneByte = parseInt(bitmap[2 + byteNumber * 2] + bitmap[3 + byteNumber * 2], 16);
      if ((oneByte & (1 << bitNumber)) > 0) {
        const { signature, messagePoint } = mcl.sign(message1, validatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures1.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint1: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures1));

    await checkpointManager.submit(checkpointMetadata, checkpoint1, aggMessagePoint1, validatorSet, bitmap);

    const message2 = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "bytes32", "uint256", "uint256", "bytes32", "bytes32", "bytes32"],
        [
          chainId,
          checkpoint2.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint2.epoch,
          checkpoint2.eventRoot,
          checkpointMetadata.currentValidatorSetHash,
          messageOfValidatorSet,
        ]
      )
    );

    const signatures2: mcl.Signature[] = [];

    aggVotingPower = 0;
    for (let i = 0; i < validatorSecretKeys.length; i++) {
      const byteNumber = Math.floor(i / 8);
      const bitNumber = i % 8;

      if (byteNumber >= bitmap.length / 2 - 1) {
        continue;
      }

      // Get the value of the bit at the given 'index' in a byte.
      const oneByte = parseInt(bitmap[2 + byteNumber * 2] + bitmap[3 + byteNumber * 2], 16);
      if ((oneByte & (1 << bitNumber)) > 0) {
        const { signature, messagePoint } = mcl.sign(message2, validatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures2.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint2: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures2));
    await checkpointManager.submit(checkpointMetadata, checkpoint2, aggMessagePoint2, validatorSet, bitmap);

    const leafIndex1 = 0;
    const leafIndex2 = 1;

    const proof1 = tree.getHexProof(leaves[leafIndex1]);
    const proof2 = tree.getHexProof(leaves[leafIndex2]);

    expect(
      await checkpointManager.getEventMembershipByBlockNumber(
        checkpoint1.blockNumber,
        leaves[leafIndex1],
        leafIndex1,
        proof1
      )
    ).to.equal(true);

    expect(
      await checkpointManager.getEventMembershipByBlockNumber(
        checkpoint2.blockNumber,
        leaves[leafIndex2],
        leafIndex2,
        proof2
      )
    ).to.equal(true);
    //----------------- Checkpoint Submit --------------------

    const batchExitInput1 = {
      blockNumber: checkpoint1.blockNumber,
      leafIndex: leafIndex1,
      unhashedLeaf: unhashedLeaf1,
      proof: proof1,
    };

    const batchExitInput2 = {
      blockNumber: checkpoint2.blockNumber,
      leafIndex: leafIndex2,
      unhashedLeaf: unhashedLeaf2,
      proof: proof2,
    };

    expect(await exitHelper.processedExits(id)).to.equal(false);
    expect(await exitHelper.processedExits(id + 1)).to.equal(false);

    const tx = await exitHelper.batchExit([batchExitInput1]);

    await expect(tx).to.emit(exitHelper, "ExitProcessed");

    expect(await exitHelper.processedExits(id)).to.equal(true);
    expect(await exitHelper.processedExits(id + 1)).to.equal(false);

    await exitHelper.batchExit([batchExitInput1, batchExitInput2]);
    expect(await exitHelper.processedExits(id + 1)).to.equal(true);
  });
});
