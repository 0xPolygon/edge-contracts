import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { randHex } from "../../ts/utils";
import { BLS, RootValidatorSet } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

describe("RootValidatorSet", () => {
  let bls: BLS,
    rootValidatorSet: RootValidatorSet,
    validatorSetSize: number,
    whitelistSize: number,
    whitelistAddresses: string[],
    signature: mcl.Signature,
    parsedPubkey: mcl.PublicKey,
    messagePoint: mcl.MessagePoint,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
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
  it("Initialize with length mismatched data", async () => {
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
    addresses.push(accounts[0].address);
    await expect(
      rootValidatorSet.initialize(bls.address, addresses, pubkeys, messagePoint)
    ).to.be.revertedWith("LENGTH_MISMATCH");
  });
  it("Initialize and validate initialization", async () => {
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
      //expect(validator.blsKey).to.equal(pubkeys[i]); typings for this aren't generated...
    }
  });
  it("Add to whitelist", async function () {
    whitelistSize = Math.floor(Math.random() * (5 - 1) + 1); // Randomly pick 1-5
    whitelistAddresses = [];
    for (let i = 0; i < whitelistSize; i++) {
      whitelistAddresses.push(accounts[i + validatorSetSize].address);
    }
    await rootValidatorSet.addToWhitelist(whitelistAddresses);
    for (let i = 0; i < whitelistSize; i++) {
      expect(await rootValidatorSet.whitelist(whitelistAddresses[i])).to.equal(
        true
      );
    }
  });
  it("Register a validator: invalid signature", async () => {
    const signer = accounts[validatorSetSize];
    const message = randHex(12);
    const { pubkey, secret } = mcl.newKeyPair();
    const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
    const newRootValidatorSet = rootValidatorSet.connect(signer);
    parsedPubkey = mcl.g2ToHex(pubkey);
    await expect(
      newRootValidatorSet.register(mcl.g1ToHex(signature), parsedPubkey)
    ).to.be.revertedWith("INVALID_SIGNATURE");
  });
  it("Register a validator: whitelisted address", async () => {
    const signer = accounts[validatorSetSize];
    const message = ethers.utils.hexlify(
      ethers.utils.toUtf8Bytes("polygon-v3-validator")
    );
    const { pubkey, secret } = mcl.newKeyPair();
    ({ signature, messagePoint } = mcl.sign(message, secret, DOMAIN));
    const newRootValidatorSet = rootValidatorSet.connect(signer);
    parsedPubkey = mcl.g2ToHex(pubkey);
    const tx = await newRootValidatorSet.register(
      mcl.g1ToHex(signature),
      parsedPubkey
    );
    const receipt = await tx.wait();
    const event = receipt.events?.find((log) => log.event === "NewValidator");
    expect(event?.args?.id).to.equal(validatorSetSize + 1);
    expect(event?.args?.validator).to.equal(signer.address);
    const parsedBlsKey = event?.args?.blsKey.map((elem: BigNumber) =>
      ethers.utils.hexValue(elem.toHexString())
    );
    const strippedParsedPubkey = parsedPubkey.map((elem: mcl.PublicKey) =>
      ethers.utils.hexValue(elem)
    );
    expect(parsedBlsKey).to.deep.equal(strippedParsedPubkey);
    expect(
      await rootValidatorSet.validatorIdByAddress(signer.address)
    ).to.equal(validatorSetSize + 1);
  });
  it("Register a validator: non-whitelisted address", async () => {
    const signer = accounts[validatorSetSize + whitelistSize];
    const newRootValidatorSet = rootValidatorSet.connect(signer);
    await expect(
      newRootValidatorSet.register(mcl.g1ToHex(signature), parsedPubkey)
    ).to.be.revertedWith("NOT_WHITELISTED");
  });
  it("Register a validator: registered address", async () => {
    const signer = accounts[0];
    await rootValidatorSet.addToWhitelist([signer.address]); // mock data
    const newRootValidatorSet = rootValidatorSet.connect(signer);
    await expect(
      newRootValidatorSet.register(mcl.g1ToHex(signature), parsedPubkey)
    ).to.be.revertedWith("ALREADY_REGISTERED");
    await rootValidatorSet.deleteFromWhitelist([signer.address]); // cleanup
  });
  it("Delete from whitelist", async function () {
    await rootValidatorSet.deleteFromWhitelist(whitelistAddresses);
    for (let i = 0; i < whitelistSize; i++) {
      expect(await rootValidatorSet.whitelist(whitelistAddresses[i])).to.be
        .false;
    }
  });
});
