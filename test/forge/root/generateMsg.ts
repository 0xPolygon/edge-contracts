import { ethers } from "hardhat";
import { BigNumberish, BigNumber } from "ethers";
import * as mcl from "../../../ts/mcl";
const input = process.argv[2];

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
const eventRoot = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

let validatorSecretKeys: any[] = [];
const validatorSetSize = Math.floor(Math.random() * (5 - 1) + 4); // Randomly pick 4-8
let aggMessagePoint: mcl.MessagePoint;
let validatorIds: any[] = [];

async function generateMsg() {
  await mcl.init();

  const accounts = await ethers.getSigners();
  let pubkeys = [];
  let addresses = [];
  for (let i = 0; i < validatorSetSize; i++) {
    const { pubkey, secret } = mcl.newKeyPair();
    validatorSecretKeys.push(secret);
    pubkeys.push(mcl.g2ToHex(pubkey));
    addresses.push(accounts[i].address);
  }

  generateSignature1();
  const output = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "address[]", "bytes32", "uint256[4][]", "bytes32", "uint256[]", "uint256[2]"],
    [validatorSetSize, addresses, DOMAIN, pubkeys, eventRoot, validatorIds, aggMessagePoint]
  );

  console.log(output);
}

function generateSignature1() {
  const id = 1;
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

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint", "tuple(uint startBlock, uint endBlock, bytes32 eventRoot)", "tuple[](address _address, uint[4] blsKey)"],
      [id, checkpoint, []]
    )
  );

  validatorIds = [];
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

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}
generateMsg();
