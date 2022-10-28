import { ethers } from "hardhat";
import { BigNumberish, BigNumber } from "ethers";
import * as mcl from "../../../ts/mcl";
const input = process.argv[2];

// let DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
// let eventRoot = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

let domain: any;
let eventRoot: any;

let validatorSecretKeys: any[] = [];
const validatorSetSize = Math.floor(Math.random() * (5 - 1) + 4); // Randomly pick 4-8
let aggMessagePoint: mcl.MessagePoint;
let aggMessagePoints: mcl.MessagePoint[] = [];
let validatorIds: any[] = [];
const minLength = Math.ceil((validatorSetSize * 2) / 3) + 1;
let accounts: any[] = [];
let newValidator: any;
let newAddress: any;

async function generateMsg() {
  const input = process.argv[2];
  const data = ethers.utils.defaultAbiCoder.decode(["bytes32", "bytes32", "address"], input);
  domain = data[0];
  eventRoot = data[1];
  newAddress = data[2];

  await mcl.init();

  accounts = await ethers.getSigners();
  let pubkeys = [];
  let addresses = [];
  for (let i = 0; i < validatorSetSize; i++) {
    const { pubkey, secret } = mcl.newKeyPair();
    validatorSecretKeys.push(secret);
    pubkeys.push(mcl.g2ToHex(pubkey));
    addresses.push(accounts[i].address);
  }

  generateSignature0();
  aggMessagePoints.push(aggMessagePoint);
  generateSignature1();
  aggMessagePoints.push(aggMessagePoint);
  generateSignature2();
  aggMessagePoints.push(aggMessagePoint);
  generateSignature3();
  aggMessagePoints.push(aggMessagePoint);
  generateSignature4();
  aggMessagePoints.push(aggMessagePoint);
  generateSignature5();
  aggMessagePoints.push(aggMessagePoint);

  const output = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "address[]", "uint256[4][]", "uint256[]", "uint256[2][]", "uint256[4]"],
    [validatorSetSize, addresses, pubkeys, validatorIds, aggMessagePoints, newValidator.blsKey]
  );

  console.log(output);
}

function generateSignature0() {
  //Invalid length
  const id = 1;
  const checkpoint = {
    startBlock: 1,
    endBlock: 101,
    eventRoot,
  };

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, []]
    )
  );

  const signatures: mcl.Signature[] = [];

  for (let i = 0; i < minLength; i++) {
    const validatorId = Math.floor(Math.random() * (validatorSetSize - 1) + 1); // 1 to validatorSetSize
    validatorIds.push(validatorId);

    const { signature, messagePoint } = mcl.sign(
      message,
      validatorSecretKeys[validatorId - 1],
      ethers.utils.arrayify(domain)
    );
    signatures.push(signature);
  }

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}

function generateSignature1() {
  //For non-sequential id
  const id = 2;
  const checkpoint = {
    startBlock: 1,
    endBlock: 101,
    eventRoot,
  };

  const blsKey: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
  ];

  newValidator = {
    _address: newAddress,
    blsKey: blsKey,
  };

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, [newValidator]]
    )
  );

  const signatures: mcl.Signature[] = [];

  for (let i = 0; i < minLength; i++) {
    const { signature, messagePoint } = mcl.sign(
      message,
      validatorSecretKeys[validatorIds[i] - 1],
      ethers.utils.arrayify(domain)
    );
    signatures.push(signature);
  }

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}

function generateSignature2() {
  // For Invalid Start Block
  const id = 1;
  const checkpoint = {
    startBlock: 2,
    endBlock: 102,
    eventRoot,
  };

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, [newValidator]]
    )
  );

  const signatures: mcl.Signature[] = [];

  for (let i = 0; i < minLength; i++) {
    const { signature, messagePoint } = mcl.sign(
      message,
      validatorSecretKeys[validatorIds[i] - 1],
      ethers.utils.arrayify(domain)
    );
    signatures.push(signature);
  }

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}

function generateSignature3() {
  // For Empty checkpoint
  const id = 1;
  const checkpoint = {
    startBlock: 1,
    endBlock: 0,
    eventRoot,
  };

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, [newValidator]]
    )
  );

  const signatures: mcl.Signature[] = [];

  for (let i = 0; i < minLength; i++) {
    const { signature, messagePoint } = mcl.sign(
      message,
      validatorSecretKeys[validatorIds[i] - 1],
      ethers.utils.arrayify(domain)
    );
    signatures.push(signature);
  }

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}

function generateSignature4() {
  // Submit without new validators
  const id = 1;
  const checkpoint = {
    startBlock: 1,
    endBlock: 101,
    eventRoot,
  };

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, []]
    )
  );

  const signatures: mcl.Signature[] = [];

  for (let i = 0; i < minLength; i++) {
    const { signature, messagePoint } = mcl.sign(
      message,
      validatorSecretKeys[validatorIds[i] - 1],
      ethers.utils.arrayify(domain)
    );
    signatures.push(signature);
  }

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}

function generateSignature5() {
  // Submit with a new validator
  const id = 1;
  const checkpoint = {
    startBlock: 1,
    endBlock: 101,
    eventRoot,
  };

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, [newValidator]]
    )
  );

  const signatures: mcl.Signature[] = [];

  for (let i = 0; i < minLength; i++) {
    const { signature, messagePoint } = mcl.sign(
      message,
      validatorSecretKeys[validatorIds[i] - 1],
      ethers.utils.arrayify(domain)
    );
    signatures.push(signature);
  }

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}
generateMsg();
