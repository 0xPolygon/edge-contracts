import { ethers } from "hardhat";
import { BigNumberish, BigNumber } from "ethers";
import { MerkleTree } from "merkletreejs";
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
let eventRoot1: any;
let eventRoot2: any;
let blockHash: any;
let currentValidatorSetHash: any;
let bitmaps: any[] = [];
let unhashedLeaves: any[] = [];
let proves: any[] = [];
let leavesArray: any[] = [];

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

  const output = ethers.utils.defaultAbiCoder.encode(
    [
      "uint256",
      "tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]",
      "uint256[2][]",
      "bytes32[]",
      "bytes[]",
      "bytes[]",
      "bytes32[][]",
      "bytes32[][]",
    ],
    [
      validatorSetSize,
      validatorSet,
      aggMessagePoints,
      [eventRoot1, blockHash, currentValidatorSetHash, eventRoot2],
      bitmaps,
      unhashedLeaves,
      proves,
      leavesArray,
    ]
  );

  console.log(output);
}

function generateSignature0() {
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

  eventRoot1 = tree.getHexRoot();
  const chainId = submitCounter;
  const checkpoint = {
    epoch: 1,
    blockNumber: 1,
    eventRoot: eventRoot1,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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

  const leafIndex = 0;
  const proof = tree.getHexProof(leaves[leafIndex]);
  unhashedLeaves.push(unhashedLeaf);
  proves.push(proof);
  leavesArray.push(leaves);
}

function generateSignature1() {
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

  eventRoot2 = tree.getHexRoot();
  const chainId = submitCounter;
  const checkpoint1 = {
    epoch: 2,
    blockNumber: 2,
    eventRoot: eventRoot2,
  };

  const checkpoint2 = {
    epoch: 3,
    blockNumber: 3,
    eventRoot: eventRoot2,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
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
      const { signature, messagePoint } = mcl.sign(message1, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures1.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint1: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures1));

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
      const { signature, messagePoint } = mcl.sign(message2, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures2.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint2: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures2));

  aggMessagePoints.push(aggMessagePoint1);
  aggMessagePoints.push(aggMessagePoint2);
  bitmaps.push(bitmap);

  const leafIndex1 = 0;
  const leafIndex2 = 1;

  const proof1 = tree.getHexProof(leaves[leafIndex1]);
  const proof2 = tree.getHexProof(leaves[leafIndex2]);
  unhashedLeaves.push(unhashedLeaf1);
  unhashedLeaves.push(unhashedLeaf2);
  proves.push(proof1);
  proves.push(proof2);
  leavesArray.push(leaves);
}

generateMsg();
