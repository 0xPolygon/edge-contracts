import { expect } from "chai";
import { ethers } from "hardhat";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { BLS, RootValidatorSet } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

describe("RootValidatorSet", function () {
  let bls: BLS, rootValidatorSet: RootValidatorSet;
  before(async function () {
    await mcl.init();
    const BLS = await ethers.getContractFactory("BLS");
    bls = await BLS.deploy();

    await bls.deployed();

    const RootValidatorSet = await ethers.getContractFactory(
      "RootValidatorSet"
    );
    rootValidatorSet = await RootValidatorSet.deploy();

    await rootValidatorSet.deployed();
  });
  it("Should be able to initialize", async function () {
    const messagePoint = mcl.g1ToHex(
      mcl.hashToPoint(
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator")),
        DOMAIN
      )
    );
    let validatorSetSize = 3;
    let addresses = [];
    let pubkeys = [];
    const accounts = await ethers.getSigners();
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      pubkeys.push(mcl.g2ToHex(pubkey));
      addresses.push(accounts[i].address);
    }
    await rootValidatorSet.initialize(
      bls.address,
      addresses,
      pubkeys,
      messagePoint
    );
  });
});
