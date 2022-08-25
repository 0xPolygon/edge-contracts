import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumberish, BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { randomBytes, hexlify, arrayify } from "ethers/lib/utils";
import { BLS, BN256G2, RootValidatorSet, CheckpointManager } from "../../typechain";

const DOMAIN = ethers.utils.hexlify(ethers.utils.randomBytes(32));

describe("CheckpointManager", () => {
  let bls: BLS,
    bn256G2: BN256G2,
    governance: string,
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

    governance = accounts[0].address;

    const BLS = await ethers.getContractFactory("BLS");
    bls = await BLS.deploy();
    await bls.deployed();

    const BN256G2 = await ethers.getContractFactory("BN256G2");
    bn256G2 = await BN256G2.deploy();
    await bn256G2.deployed();

    const RootValidatorSet = await ethers.getContractFactory("RootValidatorSet");
    rootValidatorSet = await RootValidatorSet.deploy();
    await rootValidatorSet.deployed();

    const CheckpointManager = await ethers.getContractFactory("CheckpointManager");
    checkpointManager = await CheckpointManager.deploy();
    await checkpointManager.deployed();

    eventRoot = ethers.utils.randomBytes(32);
  });

  it("Initialize and validate initialization", async () => {
    await checkpointManager.initialize(bls.address, bn256G2.address, rootValidatorSet.address, DOMAIN);
    expect(await checkpointManager.bls()).to.equal(bls.address);
    expect(await checkpointManager.bn256G2()).to.equal(bn256G2.address);
    expect(await checkpointManager.rootValidatorSet()).to.equal(rootValidatorSet.address);
    expect(await rootValidatorSet.activeValidatorSetSize()).to.equal(0);
    expect(await checkpointManager.domain()).to.equal(DOMAIN);
    const endBlock = (await checkpointManager.checkpoints(0)).endBlock;
    expect(endBlock).to.equal(0);
    startBlock = endBlock.toNumber() + 1;
    const prevId = await checkpointManager.currentCheckpointId();
    submitCounter = prevId.toNumber() + 1;
  });

  it("Initialize RootValidatorSet and validate initialization", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 4); // Randomly pick 4-8

    let addresses = [];
    let pubkeys = [];
    validatorSecretKeys = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      validatorSecretKeys.push(secret);
      pubkeys.push(mcl.g2ToHex(pubkey));
      addresses.push(accounts[i].address);
    }

    await rootValidatorSet.initialize(governance, checkpointManager.address, addresses, pubkeys);

    expect(await rootValidatorSet.currentValidatorId()).to.equal(validatorSetSize);
    expect(await rootValidatorSet.checkpointManager()).to.equal(checkpointManager.address);
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await rootValidatorSet.getValidator(i + 1);

      const parsedValidatorBlsKey = validator.blsKey.map((elem: BigNumber) =>
        ethers.utils.hexValue(elem.toHexString())
      );
      const strippedParsedPubkey = pubkeys[i].map((elem) => ethers.utils.hexValue(elem));

      expect(validator._address).to.equal(addresses[i]);
      expect(parsedValidatorBlsKey).to.deep.equal(strippedParsedPubkey);
      expect(await rootValidatorSet.validatorIdByAddress(addresses[i])).to.equal(i + 1);
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
      const { signature, messagePoint } = mcl.sign(message, key, ethers.utils.arrayify(DOMAIN));
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(checkpointManager.submit(id, checkpoint, aggMessagePoint, [], [])).to.be.revertedWith(
      "NOT_ENOUGH_SIGNATURES"
    );
  });

  it("Submit checkpoint with invalid signature", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };
    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)",
          "tuple[](address _address, uint[] blsKey)",
        ],
        [id, checkpoint, [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId], // using wrong secret key to produce non-verifiable signature
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("Submit checkpoint with non-sequential id", async () => {
    const id = submitCounter + 1; // for non-sequeantial id
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [id, checkpoint, [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * validatorSetSize + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });

  it("Submit checkpoint with invalid start block", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock + 1,
      endBlock: startBlock + 101,
      eventRoot,
    }; //invalid start block

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [id, checkpoint, [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("INVALID_START_BLOCK");
  });

  it("Submit empty checkpoint", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: 0,
      eventRoot,
    }; //endBlock < startBlock for empty checkpoint

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [id, checkpoint, [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("EMPTY_CHECKPOINT");
  });

  it("Submit checkpoint", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [id, checkpoint, [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const currentValidatorIdBeforeSubmit = await rootValidatorSet.currentValidatorId();
    await checkpointManager.submit(id, checkpoint, aggMessagePoint, validatorIds, [newValidator]);

    submitCounter = (await checkpointManager.currentCheckpointId()).toNumber() + 1;
    expect(submitCounter).to.equal(2);

    const endBlock = (await checkpointManager.checkpoints(submitCounter - 1)).endBlock;
    expect(endBlock).to.equal(101);
    startBlock = endBlock.toNumber() + 1;

    const currentValidatorIdAfterSubmit = await rootValidatorSet.currentValidatorId();
    expect(currentValidatorIdAfterSubmit.sub(1)).to.equal(currentValidatorIdBeforeSubmit);
    const lastValidator = await rootValidatorSet.getValidator(currentValidatorIdAfterSubmit);
    expect(newValidator._address).to.equal(lastValidator._address);

    const parsedValidatorBlsKey = lastValidator.blsKey.map((elem: BigNumber) =>
      ethers.utils.hexValue(elem.toHexString())
    );
    const strippedParsedPubkey = newValidator.blsKey.map((elem) => ethers.utils.hexValue(elem));
    expect(parsedValidatorBlsKey).to.deep.equal(strippedParsedPubkey);
  });

  it("Submit batch checkpoint with mismatch length", async () => {
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

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id], [checkpoint1, checkpoint2], [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submitBatch([id], [checkpoint1, checkpoint2], aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("LENGTH_MISMATCH");
  });

  it("Submit batch checkpoint with non-sequential id", async () => {
    const id = submitCounter + 1; // for non-sequential id
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id], [checkpoint], [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submitBatch([id], [checkpoint], aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("ID_NOT_SEQUENTIAL");
  });

  it("Submit batch checkpoint with invalid start block", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock + 1,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    }; //invalid startBlock

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id], [checkpoint], [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submitBatch([id], [checkpoint], aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("INVALID_START_BLOCK");
  });

  it("Submit batch empty checkpoint", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id], [checkpoint], [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submitBatch([id], [checkpoint], aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("EMPTY_CHECKPOINT");
  });

  it("Submit batch checkpoint with invalid length", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id], [checkpoint], [newValidator]]
      )
    );

    const signatures: mcl.Signature[] = [];

    for (const key of validatorSecretKeys) {
      const { signature, messagePoint } = mcl.sign(message, key, ethers.utils.arrayify(DOMAIN));
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(checkpointManager.submitBatch([id], [checkpoint], aggMessagePoint, [], [])).to.be.revertedWith(
      "NOT_ENOUGH_SIGNATURES"
    );
  });

  it("Submit batch checkpoint with invalid signature", async () => {
    const id = submitCounter;
    const checkpoint = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot,
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id], [checkpoint], [newValidator]]
      )
    );
    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId], // using wrong secret key to produce non-verifiable signature
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submitBatch([id], [checkpoint], aggMessagePoint, validatorIds, [newValidator])
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("Submit batch checkpoint", async () => {
    const id = submitCounter;
    const checkpoint1 = {
      startBlock: startBlock,
      endBlock: startBlock + 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpoint2 = {
      startBlock: startBlock + 101,
      endBlock: startBlock + 200,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ];

    const newValidator = {
      _address: accounts[0].address,
      blsKey: blsKey,
    };

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint[]",
          "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)[]",
          "tuple[](address _address, uint[4] blsKey)",
        ],
        [[id, id + 1], [checkpoint1, checkpoint2], [newValidator]]
      )
    );

    const validatorIds = [];
    const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
    const signatures: mcl.Signature[] = [];

    for (let i = 0; i < minLength; i++) {
      const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
      validatorIds.push(validatorId);

      const { signature, messagePoint } = mcl.sign(
        message,
        validatorSecretKeys[validatorId - 1],
        ethers.utils.arrayify(DOMAIN)
      );
      signatures.push(signature);
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const currentValidatorIdBeforeSubmit = await rootValidatorSet.currentValidatorId();

    await checkpointManager.submitBatch([id, id + 1], [checkpoint1, checkpoint2], aggMessagePoint, validatorIds, [
      newValidator,
    ]);

    submitCounter = (await checkpointManager.currentCheckpointId()).toNumber() + 1;
    expect(submitCounter).to.equal(4);

    const endBlock = (await checkpointManager.checkpoints(submitCounter - 1)).endBlock;
    expect(endBlock).to.equal(302);
    startBlock = endBlock.toNumber() + 1;

    const currentValidatorIdAfterSubmit = await rootValidatorSet.currentValidatorId();
    expect(currentValidatorIdAfterSubmit.sub(1)).to.equal(currentValidatorIdBeforeSubmit);
    const lastValidator = await rootValidatorSet.getValidator(currentValidatorIdAfterSubmit);
    expect(newValidator._address).to.equal(lastValidator._address);

    const parsedValidatorBlsKey = lastValidator.blsKey.map((elem: BigNumber) =>
      ethers.utils.hexValue(elem.toHexString())
    );
    const strippedParsedPubkey = newValidator.blsKey.map((elem) => ethers.utils.hexValue(elem));
    expect(parsedValidatorBlsKey).to.deep.equal(strippedParsedPubkey);
  });
});
