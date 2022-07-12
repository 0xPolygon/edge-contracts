import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumberish } from "ethers";
import * as mcl from "../../ts/mcl";

import { BLS, ChildValidatorSet, StakeManager } from "../../typechain";

const DOMAIN = ethers.utils.hexlify(ethers.utils.randomBytes(32));

describe("StakeManager", () => {
  let bls: BLS,
    childValidatorSet: ChildValidatorSet,
    stakeManager: StakeManager,
    newEpochReward: number,
    newMinSelfStake: number,
    newMinDelegation: number,
    eventRoot: any,
    validatorSecretKeys: any[],
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const BLS = await ethers.getContractFactory("BLS");
    bls = await BLS.deploy();
    await bls.deployed();

    const ChildValidatorSet = await ethers.getContractFactory(
      "ChildValidatorSet"
    );
    childValidatorSet = await ChildValidatorSet.deploy();
    await childValidatorSet.deployed();

    const StakeManager = await ethers.getContractFactory("StakeManager");
    stakeManager = await StakeManager.deploy();
    await stakeManager.deployed();

    eventRoot = ethers.utils.randomBytes(32);
  });

  it("Initialize and validate initialization", async () => {
    await stakeManager.initialize(
      newEpochReward,
      newMinSelfStake,
      newMinDelegation,
      childValidatorSet.address
    );
  });
});
