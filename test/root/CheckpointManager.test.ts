import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumberish } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { randomBytes, hexlify, arrayify } from "ethers/lib/utils";
import {
  BLS,
  BN256G2,
  RootValidatorSet,
  CheckpointManager,
} from "../../typechain";

const DOMAIN = ethers.utils.hexlify(ethers.utils.randomBytes(32));

describe("CheckpointManager", () => {
  let bls: BLS,
    bn256G2: BN256G2,
    rootValidatorSet: RootValidatorSet,
    checkpointManager: CheckpointManager,
    submitCounter: number,
    startBlock: number,
    validatorSetSize: number,
    eventRoot: any,
    validatorSecretKeys: any[],
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const BLS = await ethers.getContractFactory("BLS");
    bls = await BLS.deploy();
    await bls.deployed();

    const BN256G2 = await ethers.getContractFactory("BN256G2");
    bn256G2 = await BN256G2.deploy();
    await bn256G2.deployed();

    const RootValidatorSet = await ethers.getContractFactory(
      "RootValidatorSet"
    );
    rootValidatorSet = await RootValidatorSet.deploy();
    await rootValidatorSet.deployed();

    const CheckpointManager = await ethers.getContractFactory(
      "CheckpointManager"
    );
    checkpointManager = await CheckpointManager.deploy();
    await checkpointManager.deployed();

    eventRoot = ethers.utils.randomBytes(32);
  });

  it("Initialize and validate initialization", async () => {
    await checkpointManager.initialize(
      bls.address,
      bn256G2.address,
      rootValidatorSet.address,
      DOMAIN
    );
    expect(await checkpointManager.bls()).to.equal(bls.address);
    expect(await checkpointManager.bn256G2()).to.equal(bn256G2.address);
    expect(await checkpointManager.rootValidatorSet()).to.equal(
      rootValidatorSet.address
    );
    expect(await rootValidatorSet.activeValidatorSetSize()).to.equal(0);
    expect(await checkpointManager.domain()).to.equal(DOMAIN);
    const endBlock = (await checkpointManager.checkpoints(0)).endBlock;
    expect(endBlock).to.equal(0);
    startBlock = endBlock.toNumber() + 1;
    const prevId = await checkpointManager.currentCheckpointId();
    submitCounter = prevId.toNumber() + 1;
  });

  it("Initialize RootValidatorSet and validate initialization", async () => {
    const messagePoint = mcl.g1ToHex(
      mcl.hashToPoint(
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator")),
        ethers.utils.arrayify(DOMAIN)
      )
    );
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 4); // Randomly pick 4-8

    let addresses = [];
    let pubkeys = [];
    validatorSecretKeys = [];
    let pubkeys2 = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      validatorSecretKeys.push(secret);
      pubkeys.push(mcl.g2ToHex(pubkey));
      pubkeys2.push(pubkey);
      addresses.push(accounts[i].address);
    }

    await rootValidatorSet.initialize(
      bls.address,
      addresses,
      pubkeys,
      messagePoint
    );

    expect(await rootValidatorSet.currentValidatorId()).to.equal(
      validatorSetSize
    );
    expect(ethers.utils.hexValue(await rootValidatorSet.message(0))).to.equal(
      ethers.utils.hexValue(messagePoint[0])
    );
    expect(ethers.utils.hexValue(await rootValidatorSet.message(1))).to.equal(
      ethers.utils.hexValue(messagePoint[1])
    );
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await rootValidatorSet.validators(i + 1);
      expect(validator.id).to.equal(i + 1);
      expect(validator._address).to.equal(addresses[i]);
      expect(
        await rootValidatorSet.validatorIdByAddress(addresses[i])
      ).to.equal(i + 1);
      // expect(validator.blsKey).to.equal(pubkeys[i]); //typings for this aren't generated...
    }
  });

  it("Submit checkpoint with invalid length", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const signatures: mcl.Signature[] = [];

    for (const key of validatorSecretKeys) {
      const { signature, messagePoint } = mcl.sign(
        message,
        key,
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, [])
    ).to.be.revertedWith("NOT_ENOUGH_SIGNATURES");
  });

  it("Submit checkpoint with signature failing verification", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId], // using wrong secret key to produce non-verifiable signature
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds)
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("Submit checkpoint with non-sequential id", async () => {
    const id = submitCounter + 1; // for non-sequeantial id
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds)
    ).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });

  it("Submit checkpoint with invalid start block", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock + 1,
      endBlock: startBlock + 101,
      eventRoot,
    }; //invalid start block

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds)
    ).to.be.revertedWith("INVALID_START_BLOCK");
  });

  it("Submit empty checkpoint", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: 0,
      eventRoot,
    }; //endBlock < startBlock for empty checkpoint

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds)
    ).to.be.revertedWith("EMPTY_CHECKPOINT");
  });

  it("Submit checkpoint", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await checkpointManager.submit(
      id,
      checkpoint,
      aggMessagePoint,
      validatorIds
    );

    submitCounter =
      (await checkpointManager.currentCheckpointId()).toNumber() + 1;
    expect(submitCounter).to.equal(2);

    const endBlock = (await checkpointManager.checkpoints(1)).endBlock;
    expect(endBlock).to.equal(101);
    startBlock = endBlock.toNumber() + 1;
  });

  it("Submitbatch checkpoints with mismatch length", async () => {
    const id = submitCounter;
    const checkpoint1 = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpoint2 = {
      startBlock: startBlock + 101,
      endBlock: startBlock + 201,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
        ],
        [[id], [checkpoint1, checkpoint2]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submitBatch(
        [id],
        [checkpoint1, checkpoint2],
        aggMessagePoint,
        validatorIds
      )
    ).to.be.revertedWith("LENGTH_MISMATCH");
  });

  it("SubmitBatch checkpoints with non-sequential id", async () => {
    const id = submitCounter + 1; // for non-sequential id
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
        ],
        [[id], [checkpoint]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submitBatch(
        [id],
        [checkpoint],
        aggMessagePoint,
        validatorIds
      )
    ).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });

  it("SubmitBatch checkpoints with invalid start block", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock + 1,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    }; //invalid startBlock

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
        ],
        [[id], [checkpoint]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submitBatch(
        [id],
        [checkpoint],
        aggMessagePoint,
        validatorIds
      )
    ).to.be.revertedWith("INVALID_START_BLOCK");
  });

  it("SubmitBatch empty checkpoint", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: 1,
      endBlock: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
        ],
        [[id], [checkpoint]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submitBatch(
        [id],
        [checkpoint],
        aggMessagePoint,
        validatorIds
      )
    ).to.be.revertedWith("EMPTY_CHECKPOINT");
  });

  it("Submitbatch checkpoint with invalid length", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: 1,
      endBlock: 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)"],
        [id, checkpoint]
      )
    );

    const signatures: mcl.Signature[] = [];

    for (const key of validatorSecretKeys) {
      const { signature, messagePoint } = mcl.sign(
        message,
        key,
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submitBatch([id], [checkpoint], aggMessagePoint, [])
    ).to.be.revertedWith("NOT_ENOUGH_SIGNATURES");
  });

  it("Submitbatch checkpoint with signature failing verification", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: 100,
      endBlock: 200,
      eventRoot,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
        ],
        [[id], [checkpoint]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId], // using wrong secret key to produce non-verifiable signature
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await expect(
      checkpointManager.submitBatch(
        [id],
        [checkpoint],
        aggMessagePoint,
        validatorIds
      )
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("SubmitBatch checkpoint", async () => {
    const id = submitCounter;
    const checkpoint1 = {
      startBlock: 101,
      endBlock: 200,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpoint2 = {
      startBlock: 201,
      endBlock: 300,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
        ],
        [
          [id, id + 1],
          [checkpoint1, checkpoint2],
        ]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(
        Math.random() * (validatorSetSize - 1) + 1
      ); // 1 - validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(
      mcl.aggregateRaw(signatures)
    );

    await checkpointManager.submitBatch(
      [id, id + 1],
      [checkpoint1, checkpoint2],
      aggMessagePoint,
      validatorIds
    );
  });
});
