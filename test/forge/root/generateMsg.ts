import { ethers } from "hardhat";
import { BigNumberish, BigNumber } from "ethers";
import * as mcl from "../../../ts/mcl";
const input = process.argv[2];

// let DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
// let eventRoot = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

let domain: any;
let eventRoot: any;

let validatorSecretKeys: any[] = [];
const validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12
let aggMessagePoint: mcl.MessagePoint;
let aggMessagePoints: mcl.MessagePoint[] = [];
let accounts: any[] = [];
let newValidator: any;
let newAddress: any;
let validatorSet: any[] = [];

async function generateMsg() {
  const input = process.argv[2];
  const data = ethers.utils.defaultAbiCoder.decode(["bytes32", "bytes32", "address"], input);
  domain = data[0];
  eventRoot = data[1];
  newAddress = data[2];

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

  generateSignature0();
  aggMessagePoints.push(aggMessagePoint);

  const output = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]", "uint256[2][]"],
    [validatorSetSize, validatorSet, aggMessagePoints]
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

  aggMessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
}

generateMsg();
