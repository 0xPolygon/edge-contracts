import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { BLS, ChildValidatorSet } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

describe("RootValidatorSet", () => {
  let bls: BLS,
    childValidatorSet: ChildValidatorSet,
    validatorSetSize: number,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const ChildValidatorSet = await ethers.getContractFactory(
      "ChildValidatorSet"
    );
    childValidatorSet = await ChildValidatorSet.deploy();

    await childValidatorSet.deployed();
  });
  it("Initialize and validate initialization", async () => {
    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });
    const signer = await ethers.getSigner(
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"
    );
    const newChildValidatorSet = childValidatorSet.connect(signer);
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 1); // Randomly pick 1-5
    const validatorStake = ethers.utils.parseEther(
      String(Math.floor(Math.random() * (10000 - 1000) + 1000))
    );
    const validatorStakes = Array(validatorSetSize).fill(validatorStake);
    const addresses = [];
    const pubkeys = [];
    const validatorSet = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      pubkeys.push(mcl.g2ToHex(pubkey));
      addresses.push(accounts[i].address);
      validatorSet.push(i + 1);
    }
    await newChildValidatorSet.initialize(
      addresses,
      pubkeys,
      validatorStakes,
      validatorSet,
      validatorSet
    );
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });
    expect(await childValidatorSet.currentValidatorId()).to.equal(
      validatorSetSize
    );
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await childValidatorSet.validators(i + 1);
      expect(validator.id).to.equal(i + 1);
      expect(validator._address).to.equal(addresses[i]);
      expect(validator.selfStake).to.equal(validatorStake);
      expect(validator.stake).to.equal(validatorStake);
    }
  });
});
