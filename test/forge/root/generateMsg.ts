import { ethers } from "hardhat";
import { BigNumberish, BigNumber } from "ethers";
import * as mcl from "../../../ts/mcl";
const input = process.argv[2];

// let DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
// let eventRoot = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

let domain: any;

let validatorSecretKeys: any[] = [];
const validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12
let aggMessagePoints: mcl.MessagePoint[] = [];
let accounts: any[] = [];
let newValidator: any;
let newAddress: any;
let validatorSet: any[] = [];
let submitCounter: number;
let eventRoot: any;
let blockHash: any;
let currentValidatorSetHash: any;
let bitmaps: any[] = [];
let aggVotingPowers: any[] = [];

async function generateMsg() {
  const input = process.argv[2];
  const data = ethers.utils.defaultAbiCoder.decode(["bytes32"], input);
  domain = data[0];

  await mcl.init();

  accounts = await ethers.getSigners();
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

  eventRoot = ethers.utils.hexlify(ethers.utils.randomBytes(32));
  blockHash = ethers.utils.hexlify(ethers.utils.randomBytes(32));
  currentValidatorSetHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
      [validatorSet]
    )
  );
  submitCounter = 1;

  generateSignature0();
  generateSignature1();
  generateSignature2();
  generateSignature3();
  generateSignature4();
  generateSignature5();
  generateSignature6();
  generateSignature7();
  generateSignature8();

  const output = ethers.utils.defaultAbiCoder.encode(
    [
      "uint256",
      "tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]",
      "uint256[2][]",
      "bytes32[]",
      "bytes[]",
      "uint256[]",
    ],
    [
      validatorSetSize,
      validatorSet,
      aggMessagePoints,
      [eventRoot, blockHash, currentValidatorSetHash],
      bitmaps,
      aggVotingPowers,
    ]
  );

  console.log(output);
}

function generateSignature0() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 0,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature1() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 1,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature2() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 1,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature3() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 1,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature4() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 0,
    blockNumber: 0,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature5() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 0,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature6() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 2,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature7() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 2,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
  };

  const bitmapStr = "ff";

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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature8() {
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 2,
    eventRoot,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
  };

  const bitmapNum = Math.floor(Math.random() * 0xffffffffffffffff);
  let bitmapStr = bitmapNum.toString(16);
  const length = bitmapStr.length;
  for (let j = 0; j < 16 - length; j++) {
    bitmapStr = "0" + bitmapStr;
  }

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
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ]
    )
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

generateMsg();
