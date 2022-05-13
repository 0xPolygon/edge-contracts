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

describe("ChildValidatorSet", () => {
  let bls: BLS,
    rootValidatorSetAddress: string,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    validatorSetSize: number,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    rootValidatorSetAddress = "0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287";

    const ChildValidatorSet = await ethers.getContractFactory(
      "ChildValidatorSet"
    );
    childValidatorSet = await ChildValidatorSet.deploy();

    await childValidatorSet.deployed();

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
    systemChildValidatorSet = childValidatorSet.connect(signer);
  });
  it("Initialize without system call", async () => {
    await expect(
      childValidatorSet.initialize(rootValidatorSetAddress, [], [], [], [])
    ).to.be.revertedWith("ONLY_SYSTEMCALL");
  });
  it("Initialize and validate initialization", async () => {
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
    await systemChildValidatorSet.initialize(
      rootValidatorSetAddress,
      addresses,
      pubkeys,
      validatorStakes,
      validatorSet
    );
    expect(await childValidatorSet.currentValidatorId()).to.equal(
      validatorSetSize
    );
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await childValidatorSet.validators(i + 1);
      expect(validator.id).to.equal(i + 1);
      expect(validator._address).to.equal(addresses[i]);
      expect(validator.selfStake).to.equal(validatorStake);
      expect(validator.stake).to.equal(validatorStake);
      expect(
        await childValidatorSet.validatorIdByAddress(addresses[i])
      ).to.equal(validator.id);
    }
    // struct array is not available on typechain
    //expect(await childValidatorSet.epochs(1).validatorSet).to.deep.equal(validatorSet);
  });
  it("Attempt reinitialization", async () => {
    await expect(
      systemChildValidatorSet.initialize(rootValidatorSetAddress, [], [], [], [])
    ).to.be.revertedWith("ALREADY_INITIALIZED");
  });
  it("Commit epoch without system call", async () => {
    await expect(
      childValidatorSet.commitEpoch(0, 0, 0, ethers.utils.randomBytes(32))
    ).to.be.revertedWith("ONLY_SYSTEMCALL");
  });
  it("Commit epoch with unexpected id", async () => {
    await expect(
      systemChildValidatorSet.commitEpoch(0, 0, 0, ethers.utils.randomBytes(32))
    ).to.be.revertedWith("UNEXPECTED_EPOCH_ID");
  });
  it("Commit epoch with no blocks committed", async () => {
    await expect(
      systemChildValidatorSet.commitEpoch(1, 0, 0, ethers.utils.randomBytes(32))
    ).to.be.revertedWith("NO_BLOCKS_COMMITTED");
  });
  it("Commit epoch with incomplete sprint", async () => {
    await expect(
      systemChildValidatorSet.commitEpoch(1, 1, 63, ethers.utils.randomBytes(32))
    ).to.be.revertedWith("INCOMPLETE_SPRINT");
  });
  it("Commit epoch", async () => {
    await expect(
      systemChildValidatorSet.commitEpoch(1, 1, 64, ethers.utils.randomBytes(32))
    );
  });
  it("Commit epoch with old block", async () => {
    await expect(
      systemChildValidatorSet.commitEpoch(2, 64, 127, ethers.utils.randomBytes(32))
    ).to.be.revertedWith("BLOCK_IN_COMMITTED_EPOCH");
  });
});
