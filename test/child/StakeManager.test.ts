import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import * as hre from "hardhat";

import { ChildValidatorSet, StakeManager } from "../../typechain";

describe("StakeManager", () => {
  let rootValidatorSetAddress: string,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    stakeManager: StakeManager,
    epochReward: number,
    minSelfStake: number,
    minDelegation: number,
    validatorSetSize: number,
    validatorStake: BigNumber,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    rootValidatorSetAddress = ethers.Wallet.createRandom().address;

    const ChildValidatorSet = await ethers.getContractFactory(
      "ChildValidatorSet"
    );
    childValidatorSet = await ChildValidatorSet.deploy();
    await childValidatorSet.deployed();

    const StakeManager = await ethers.getContractFactory("StakeManager");
    stakeManager = await StakeManager.deploy();
    await stakeManager.deployed();

    epochReward = 1;
    minSelfStake = 10000;
    minDelegation = 10000;

    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });

    const systemSigner = await ethers.getSigner(
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"
    );
    systemChildValidatorSet = childValidatorSet.connect(systemSigner);
  });

  it("Initialize and validate initialization", async () => {
    await stakeManager.initialize(
      epochReward,
      minSelfStake,
      minDelegation,
      childValidatorSet.address
    );

    expect(await stakeManager.epochReward()).to.equal(epochReward);
    expect(await stakeManager.minSelfStake()).to.equal(minSelfStake);
    expect(await stakeManager.minDelegation()).to.equal(minDelegation);

    expect(await stakeManager.childValidatorSet()).to.equal(
      childValidatorSet.address
    );
  });

  it("Initialize ChildValidatorSet and validate initialization", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 1); // Randomly pick 1-5
    validatorStake = ethers.utils.parseEther(
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
      stakeManager.address,
      addresses,
      pubkeys,
      validatorStakes,
      validatorSet
    );
    expect(await childValidatorSet.currentValidatorId()).to.equal(
      validatorSetSize
    );
    expect(await childValidatorSet.stakeManager()).to.equal(
      stakeManager.address
    );
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await childValidatorSet.validators(i + 1);
      expect(validator._address).to.equal(addresses[i]);
      expect(validator.selfStake).to.equal(validatorStake);
      expect(validator.totalStake).to.equal(validatorStake);
      expect(
        await childValidatorSet.validatorIdByAddress(addresses[i])
      ).to.equal(i + 1);
    }
  });

  it("SelfStake less amount than minSelfStake", async () => {
    await expect(stakeManager.selfStake({ value: 100 })).to.be.revertedWith(
      "STAKE_TOO_LOW"
    );
  });

  it("SelfStake with invalid sender", async () => {
    await expect(
      stakeManager
        .connect(accounts[validatorSetSize + 1])
        .selfStake({ value: minSelfStake + 1 })
    ).to.be.revertedWith("INVALID_SENDER");
  });

  it("SelfStake", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    const beforeSelfStake = (await childValidatorSet.validators(id)).selfStake;

    await stakeManager.selfStake({ value: minSelfStake + 1 });

    const afterSelfStake = (await childValidatorSet.validators(id)).selfStake;
    expect(afterSelfStake.sub(beforeSelfStake)).to.equal(minSelfStake + 1);
  });
});
