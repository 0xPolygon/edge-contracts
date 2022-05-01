import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { BLS, RootValidatorSet } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

describe("RootValidatorSet", function () {
  let bls: BLS,
    rootValidatorSet: RootValidatorSet,
    validatorSetSize: number,
    accounts: any[]; // we use any so we can access address directly from object
  before(async function () {
    await mcl.init();
    accounts = await ethers.getSigners();
    const BLS = await ethers.getContractFactory("BLS");
    bls = await BLS.deploy();

    await bls.deployed();

    const RootValidatorSet = await ethers.getContractFactory(
      "RootValidatorSet"
    );
    rootValidatorSet = await RootValidatorSet.deploy();

    await rootValidatorSet.deployed();
  });
  it("Initialize and validate initialization", async function () {
    const messagePoint = mcl.g1ToHex(
      mcl.hashToPoint(
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator")),
        DOMAIN
      )
    );
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 1); // Randomly pick 1-5
    let addresses = [];
    let pubkeys = [];
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
    expect(await rootValidatorSet.currentValidatorId()).to.equal(
      validatorSetSize + 1
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
      //expect(validator.blsKey).to.equal(pubkeys[i]); typings for this aren't generated...
    }
  });
  it("Add to whitelist", async function () {
    const whitelistSize = Math.floor(Math.random() * (5 - 1) + 1); // Randomly pick 1-5
    const addresses: string[] = [];
    for (let i = 0; i < whitelistSize; i++) {
      addresses.push(accounts[i + validatorSetSize].address);
    }
    await rootValidatorSet.addToWhitelist(addresses);
    expect(await rootValidatorSet.viewWhitelist()).to.deep.equal(addresses);
  });
});
