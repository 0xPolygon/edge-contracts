import { expect } from "chai";
import { ethers } from "hardhat";
import * as mcl from "../../ts/mcl";
import { BLS, BN256G2, CheckpointManager } from "../../typechain-types";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_CHECKPOINT_MANAGER"]));

describe("CheckpointManager", () => {
  let bls: BLS,
    bn256G2: BN256G2,
    checkpointManager: CheckpointManager,
    submitCounter: number,
    validatorSetSize: number,
    validatorSecretKeys: any[],
    validatorSet: any[],
    validatorSetHash: any,
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
  });

  it("Initialize and validate initialization", async () => {
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
    validatorSetHash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
        [validatorSet]
      )
    );

    await checkpointManager.initialize(bls.address, bn256G2.address, chainId, validatorSetHash);
    expect(await checkpointManager.bls()).to.equal(bls.address);
    expect(await checkpointManager.bn256G2()).to.equal(bn256G2.address);

    const endBlock = (await checkpointManager.checkpoints(0)).blockNumber;
    expect(endBlock).to.equal(0);
    const prevId = await checkpointManager.currentEpoch();
    submitCounter = prevId.toNumber() + 1;
  });

  it("Submit checkpoint with invalid validator set", async () => {
    const chainId = submitCounter;
    const checkpoint = {
      epoch: 1,
      blockNumber: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    let invalidValidatorSet = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      invalidValidatorSet.push({
        _address: accounts[i].address,
        blsKey: mcl.g2ToHex(pubkey),
        votingPower: ethers.utils.parseEther(((i + 1) * 2).toString()),
      });
    }
    invalidValidatorSet[0].votingPower = invalidValidatorSet[0].votingPower.add(1);

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: invalidValidatorSet,
    };

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;
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
          chainId + 1, //for signature verify fail
          checkpoint.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint.epoch,
          checkpoint.eventRoot,
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
    ).to.be.revertedWith("INVALID_VALIDATOR_SET_HASH");
  });

  it("Submit checkpoint with invalid signature", async () => {
    const checkpoint = {
      epoch: 1,
      blockNumber: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;
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
          chainId + 1, //for signature verify fail
          checkpoint.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint.epoch,
          checkpoint.eventRoot,
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("Submit checkpoint with empty bitmap", async () => {
    const checkpoint = {
      epoch: 1,
      blockNumber: 1,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    const bitmapStr = "00";

    const bitmap = `0x${bitmapStr}`;
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
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
    ).to.be.revertedWith("BITMAP_IS_EMPTY");
  });

  it("Submit checkpoint with not enough voting power", async () => {
    const checkpoint = {
      epoch: 1,
      blockNumber: 1,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    const bitmapStr = "01";

    const bitmap = `0x${bitmapStr}`;
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
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
    ).to.be.revertedWith("INSUFFICIENT_VOTING_POWER");
  });

  it("Submit checkpoint success", async () => {
    const checkpoint = {
      epoch: 1,
      blockNumber: 1,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    // const bitmapNum = Math.floor(Math.random() * 0xffffffffffffffff);
    // let bitmapStr = bitmapNum.toString(16);
    // const length = bitmapStr.length;
    // for (let j = 0; j < 16 - length; j++) {
    //   bitmapStr = "0" + bitmapStr;
    // }

    // const bitmap = `0x${bitmapStr}`;
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
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap);

    expect(await checkpointManager.getEventRootByBlock(checkpoint.blockNumber)).to.equal(checkpoint.eventRoot);
    expect(await checkpointManager.checkpointBlockNumbers(0)).to.equal(checkpoint.blockNumber);
    expect(await checkpointManager.getCheckpointBlock(1)).to.deep.equal([true, checkpoint.blockNumber]);
    expect(await checkpointManager.getCheckpointBlock(checkpoint.blockNumber + 1)).to.deep.equal([false, 0]);

    const leafIndex = 0;
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
    await checkpointManager.getEventMembershipByBlockNumber(
      checkpoint.blockNumber,
      checkpoint.eventRoot,
      leafIndex,
      proof
    );
    await checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
  });

  it("Submit checkpoint with invalid epoch", async () => {
    const checkpoint = {
      epoch: 0,
      blockNumber: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;
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
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
    ).to.be.revertedWith("INVALID_EPOCH");
  });

  it("Submit checkpoint with empty checkpoint", async () => {
    const checkpoint = {
      epoch: 1,
      blockNumber: 0,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;
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
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await expect(
      checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
    ).to.be.revertedWith("EMPTY_CHECKPOINT");
  });

  it("Submit checkpoint success with same epoch", async () => {
    const checkpoint = {
      epoch: 1,
      blockNumber: 2,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    // const bitmapNum = Math.floor(Math.random() * 0xffffffffffffffff);
    // let bitmapStr = bitmapNum.toString(16);
    // const length = bitmapStr.length;
    // for (let j = 0; j < 16 - length; j++) {
    //   bitmapStr = "0" + bitmapStr;
    // }

    // const bitmap = `0x${bitmapStr}`;
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
          validatorSetHash,
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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap);

    expect(await checkpointManager.getEventRootByBlock(checkpoint.blockNumber)).to.equal(checkpoint.eventRoot);
    expect(await checkpointManager.checkpointBlockNumbers(0)).to.equal(checkpoint.blockNumber);
    expect(await checkpointManager.getCheckpointBlock(1)).to.deep.equal([true, checkpoint.blockNumber]);
    expect(await checkpointManager.getCheckpointBlock(checkpoint.blockNumber + 1)).to.deep.equal([false, 0]);

    const leafIndex = 0;
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
    await checkpointManager.getEventMembershipByBlockNumber(
      checkpoint.blockNumber,
      checkpoint.eventRoot,
      leafIndex,
      proof
    );
    await checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
  });

  it("Submit checkpoint success with short bitmap", async () => {
    const checkpoint = {
      epoch: 2,
      blockNumber: 3,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    const checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    const bitmap = "0xff";
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
          validatorSetHash,
          messageOfValidatorSet,
        ]
      )
    );

    const signatures: mcl.Signature[] = [];

    let totalVotingPower = 0;
    for (let i = 0; i < validatorSetSize; i++) {
      totalVotingPower = totalVotingPower + Number(validatorSet[i].votingPower);
    }

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

    if (aggVotingPower > (totalVotingPower * 2) / 3) {
      await checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap);

      expect(await checkpointManager.getEventRootByBlock(checkpoint.blockNumber)).to.equal(checkpoint.eventRoot);
      expect(await checkpointManager.checkpointBlockNumbers(1)).to.equal(checkpoint.blockNumber);
      expect(await checkpointManager.getCheckpointBlock(checkpoint.blockNumber)).to.deep.equal([
        true,
        checkpoint.blockNumber,
      ]);
      expect(await checkpointManager.getCheckpointBlock(checkpoint.blockNumber + 1)).to.deep.equal([false, 0]);

      const leafIndex = 0;
      let proof = [];
      proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
      await checkpointManager.getEventMembershipByBlockNumber(
        checkpoint.blockNumber,
        checkpoint.eventRoot,
        leafIndex,
        proof
      );
      await checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
    } else {
      await expect(
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, validatorSetHash, bitmap)
      ).to.be.revertedWith("INSUFFICIENT_VOTING_POWER");
    }
  });

  it("Get Event Membership By BlockNumber with invalid eventRoot", async () => {
    const blockNumber = 4;
    const leaf = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const leafIndex = 0;
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

    await expect(
      checkpointManager.getEventMembershipByBlockNumber(blockNumber, leaf, leafIndex, proof)
    ).to.be.revertedWith("NO_EVENT_ROOT_FOR_BLOCK_NUMBER");
  });

  it("Get Event Membership By epoch with invalid eventRoot", async () => {
    const epoch = 3;
    const leaf = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const leafIndex = 0;
    let proof = [];
    proof.push(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

    await expect(checkpointManager.getEventMembershipByEpoch(epoch, leaf, leafIndex, proof)).to.be.revertedWith(
      "NO_EVENT_ROOT_FOR_EPOCH"
    );
  });

  it("Change validator keys plus deterministic gas measurement for submit", async () => {
    let newValidatorSetSize = 9

    let newValidatorSecretKeys = [];
    let newValidatorSet = [];
    for (let i = 0; i < newValidatorSetSize; i++) {
      const secret1 = i + 7;
      const secret = mcl.parseFr("0x" + secret1);
      const pubkey = mcl.getPubkey(secret);
      newValidatorSecretKeys.push(secret);
      newValidatorSet.push({
        _address: accounts[i].address,
        blsKey: mcl.g2ToHex(pubkey),
        votingPower: ethers.utils.parseEther(((i + 1) * 2).toString()),
      });
    }
    let newValidatorSetHash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
        [newValidatorSet]
      )
    );


    let checkpoint = {
      epoch: 2,
      blockNumber: 100,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    let checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: validatorSet,
    };

    let bitmap = "0xffff";

    let message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "bytes32", "uint256", "uint256", "bytes32", "bytes32", "bytes32"],
        [
          chainId,
          checkpoint.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint.epoch,
          checkpoint.eventRoot,
          validatorSetHash,
          newValidatorSetHash,
        ]
      )
    );

    let signatures: mcl.Signature[] = [];

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
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    let aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    await checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, newValidatorSetHash, bitmap);

    // Now switched to deterministic validator set
    checkpoint = {
      epoch: 3,
      blockNumber: 200,
      eventRoot: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    };

    checkpointMetadata = {
      blockHash: ethers.utils.hexlify(ethers.utils.randomBytes(32)),
      blockRound: 0,
      currentValidatorSet: newValidatorSet,
    };

    bitmap = "0xffff";

    message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "bytes32", "uint256", "uint256", "bytes32", "bytes32", "bytes32"],
        [
          chainId,
          checkpoint.blockNumber,
          checkpointMetadata.blockHash,
          checkpointMetadata.blockRound,
          checkpoint.epoch,
          checkpoint.eventRoot,
          newValidatorSetHash,
          newValidatorSetHash,
        ]
      )
    );

    signatures = [];

    aggVotingPower = 0;
    for (let i = 0; i < newValidatorSecretKeys.length; i++) {
      const byteNumber = Math.floor(i / 8);
      const bitNumber = i % 8;

      if (byteNumber >= bitmap.length / 2 - 1) {
        continue;
      }

      // Get the value of the bit at the given 'index' in a byte.
      const oneByte = parseInt(bitmap[2 + byteNumber * 2] + bitmap[3 + byteNumber * 2], 16);
      if ((oneByte & (1 << bitNumber)) > 0) {
        const { signature, messagePoint } = mcl.sign(message, newValidatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(newValidatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const tx1 = await checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoint, newValidatorSetHash, bitmap);
    const receipt = await tx1.wait()
    console.log(receipt.gasUsed);
  });
});
