import { impersonateAccount, mine, stopImpersonatingAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { ForkParams } from "../../typechain-types";

describe("ForkParams", () => {
  let forkParams: ForkParams, accounts: SignerWithAddress[], futureBlockNumber: number;
  before(async () => {
    accounts = await ethers.getSigners();
    const forkParamsFactory = await ethers.getContractFactory("ForkParams");
    forkParams = (await forkParamsFactory.deploy(accounts[0].address)) as ForkParams;

    await forkParams.deployed();
  });

  it("validate deployment", async () => {
    expect(await forkParams.owner()).to.equal(accounts[0].address);
  });

  it("add new feature from wrong account", async () => {
    await impersonateAccount(accounts[1].address);
    const newForkParams = forkParams.connect(accounts[1]);
    await expect(newForkParams.addNewFeature(1, "FEATURE")).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("add feature for wrong block", async () => {
    await expect(forkParams.addNewFeature(0, "FEATURE")).to.be.revertedWith("ForkParams: INVALID_BLOCK");
  });

  it("add feature success", async () => {
    futureBlockNumber = (await ethers.provider.getBlockNumber()) + Math.floor(Math.random() * 10 + 10);
    await forkParams.addNewFeature(futureBlockNumber, "FEATURE");
    expect(
      await forkParams.featureToBlockNumber(
        ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["string"], ["FEATURE"]))
      )
    ).to.equal(BigNumber.from(futureBlockNumber));
  });

  it("add feature fail, feature exists", async () => {
    await expect(forkParams.addNewFeature(futureBlockNumber, "FEATURE")).to.be.revertedWith(
      "ForkParams: FEATURE_EXISTS"
    );
  });

  it("fetch feature revert on non-existent feature", async () => {
    await expect(forkParams.isFeatureActivated("FEATURE_1")).to.be.revertedWith("ForkParams: NONEXISTENT_FEATURE");
  });

  it("fetch feature success before activation", async () => {
    expect(await forkParams.isFeatureActivated("FEATURE")).to.be.false;
  });

  it("reschedule feature fail, old block", async () => {
    await expect(forkParams.updateFeatureBlock(3, "FEATURE")).to.be.revertedWith("ForkParams: INVALID_BLOCK");
  });

  it("reschedule feature fail, feature does not exist", async () => {
    await expect(forkParams.updateFeatureBlock(futureBlockNumber, "FEATURE_1")).to.be.revertedWith(
      "ForkParams: NONEXISTENT_FEATURE"
    );
  });

  it("reschedule feature success", async () => {
    futureBlockNumber += Math.floor(Math.random() * 5 + 1);
    await forkParams.updateFeatureBlock(futureBlockNumber, "FEATURE");
    expect(
      await forkParams.featureToBlockNumber(
        ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["string"], ["FEATURE"]))
      )
    ).to.equal(BigNumber.from(futureBlockNumber));
  });

  it("fetch feature success after activation", async () => {
    mine(futureBlockNumber - (await ethers.provider.getBlockNumber()));
    expect(await forkParams.isFeatureActivated("FEATURE")).to.be.true;
  });

  it("reschedule feature fail, feature activated", async () => {
    await expect(forkParams.updateFeatureBlock(futureBlockNumber, "FEATURE")).to.be.revertedWith(
      "ForkParams: INVALID_BLOCK"
    );
  });
});
