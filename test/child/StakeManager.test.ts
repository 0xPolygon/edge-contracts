import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import * as hre from "hardhat";
import { randHex } from "../../ts/utils";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";

import { ChildValidatorSet, StakeManager } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

describe("StakeManager", () => {
  let rootValidatorSetAddress: string,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    stakeManager: StakeManager,
    systemStakeManager: StakeManager,
    epochReward: BigNumber,
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

    epochReward = ethers.utils.parseEther("0.0000001");
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
    systemStakeManager = stakeManager.connect(systemSigner);
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
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 5); // Randomly pick 5-9
    // validatorSetSize = 4; // constnatly 4
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
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    await expect(stakeManager.selfStake(id, { value: 100 })).to.be.revertedWith(
      "STAKE_TOO_LOW"
    );
  });

  it("SelfStake with invalid validator id", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    await expect(
      stakeManager.selfStake(id.add(1), { value: minSelfStake + 1 })
    ).to.be.revertedWith("ONLY_VALIDATOR");
  });

  it("SelfStake", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const selfStakeAmount = minSelfStake + 1;
    const beforeSelfStake = (await childValidatorSet.validators(id)).selfStake;

    await stakeManager.selfStake(id, { value: selfStakeAmount });

    const afterSelfStake = (await childValidatorSet.validators(id)).selfStake;
    expect(afterSelfStake.sub(beforeSelfStake)).to.equal(selfStakeAmount);
  });

  it("Delegate less amount than minDelegation", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const idToDelegate = id.add(1);
    const restake = false;

    await expect(
      stakeManager.delegate(idToDelegate, restake, { value: 100 })
    ).to.be.revertedWith("DELEGATION_TOO_LOW");
  });

  it("Delegate to invalid id", async () => {
    const idToDelegate = await childValidatorSet.currentValidatorId();
    const restake = false;

    await expect(
      stakeManager.delegate(idToDelegate, restake, { value: minDelegation + 1 })
    ).to.be.revertedWith("INVALID_VALIDATOR_ID");
  });

  it("Delegate for the first time", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const delegateAmount = minDelegation + 1;
    const idToDelegate = id.add(1);
    const restake = false;

    const beforeDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;

    await stakeManager.delegate(idToDelegate, restake, {
      value: delegateAmount,
    });

    const delegation = await stakeManager.delegations(
      accounts[0].address,
      idToDelegate
    );
    const currentEpochId = await childValidatorSet.currentEpochId();
    expect(delegation.epochId).to.equal(currentEpochId.sub(1));
    expect(delegation.amount).to.equal(delegateAmount);

    const afterDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;
    expect(afterDelegate.sub(beforeDelegate)).to.equal(delegateAmount);
  });

  it("Delegate again without restake", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const delegateAmount = minDelegation + 1;
    const idToDelegate = id.add(1);
    const restake = false;

    const beforeDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;
    const balanceBeforeReDelegate = await ethers.provider.getBalance(
      accounts[0].address
    );

    const txResp = await stakeManager.delegate(idToDelegate, restake, {
      value: delegateAmount,
    });
    const txReceipt = await txResp.wait();
    const delegateGas = ethers.BigNumber.from(
      txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice)
    ).add(10001);

    const delegation = await stakeManager.delegations(
      accounts[0].address,
      idToDelegate
    );
    const currentEpochId = await childValidatorSet.currentEpochId();
    expect(delegation.epochId).to.equal(currentEpochId.sub(1));
    expect(delegation.amount).to.equal(delegateAmount * 2);

    const delegatorReward = await stakeManager.calculateDelegatorReward(
      idToDelegate,
      accounts[0].address
    );

    const afterDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;
    const balanceAfterReDelegate = await ethers.provider.getBalance(
      accounts[0].address
    );

    expect(afterDelegate.sub(beforeDelegate)).to.equal(
      delegatorReward.add(delegateAmount)
    );
    expect(
      balanceBeforeReDelegate.sub(delegateGas).add(delegatorReward)
    ).to.equal(balanceAfterReDelegate);
  });

  it("Delegate again with restake", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const delegateAmount = minDelegation + 1;
    const idToDelegate = id.add(1);
    const restake = false;

    const beforeDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;

    await stakeManager.delegate(idToDelegate, restake, {
      value: delegateAmount,
    });

    const delegation = await stakeManager.delegations(
      accounts[0].address,
      idToDelegate
    );

    const currentEpochId = await childValidatorSet.currentEpochId();
    expect(delegation.epochId).to.equal(currentEpochId.sub(1));

    const delegatorReward = await stakeManager.calculateDelegatorReward(
      idToDelegate,
      accounts[0].address
    );
    expect(delegation.amount).to.equal(delegatorReward.add(delegateAmount * 3));

    const afterDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;
    expect(afterDelegate.sub(beforeDelegate)).to.equal(
      delegatorReward.add(delegateAmount)
    );
  });

  it("Claim delegatorReward", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const idToDelegate = id.add(1);

    const delegatorReward = await stakeManager.calculateDelegatorReward(
      idToDelegate,
      accounts[0].address
    );

    const balanceBeforeReDelegate = await ethers.provider.getBalance(
      accounts[0].address
    );

    const txResp = await stakeManager.claimDelegatorReward(idToDelegate);
    const txReceipt = await txResp.wait();
    const claimGas = ethers.BigNumber.from(
      txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice)
    );

    const delegation = await stakeManager.delegations(
      accounts[0].address,
      idToDelegate
    );

    const currentEpochId = await stakeManager.lastRewardedEpochId();
    expect(delegation.epochId).to.equal(currentEpochId);

    const balanceAfterReDelegate = await ethers.provider.getBalance(
      accounts[0].address
    );
    expect(balanceBeforeReDelegate.sub(claimGas).add(delegatorReward)).to.equal(
      balanceAfterReDelegate
    );
  });

  it("Distribute without child validator set", async () => {
    const uptime = {
      epochId: 0,
      uptimes: [0],
      totalUptime: 0,
    };

    const signature = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)"],
        [uptime]
      )
    );

    await expect(stakeManager.distributeRewards(uptime)).to.be.revertedWith(
      "ONLY_VALIDATOR_SET"
    );
  });

  it("Distribute with invalid epoch id", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
    const id = 1;
    const epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [0],
    };

    const epochId = await stakeManager.lastRewardedEpochId();
    const currentValidatorId = await childValidatorSet.currentValidatorId();

    const uptime = {
      epochId: epochId,
      uptimes: [1000000000000],
      totalUptime: 0,
    };

    for (let i = 0; i < currentValidatorId.toNumber() - 2; i++) {
      uptime.uptimes.push(1000000000000);
    }

    const signature = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint256",
          "tuple(uint256 startBlock, uint256 endBlock, bytes32 epochRoot, uint256[] validatorSet)",
          "tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)",
        ],
        [id, epoch, uptime]
      )
    );

    await expect(
      systemChildValidatorSet.commitEpoch(id, epoch, uptime, signature)
    ).to.be.revertedWith("INVALID_EPOCH_ID");
  });

  // it("Distribute with not committed epoch", async () => {
  //   await hre.network.provider.send("hardhat_setCode", [
  //     "0x0000000000000000000000000000000000002030",
  //     alwaysTrueBytecode,
  //   ]);
  //   const id = 1;
  //   const epoch = {
  //     startBlock: BigNumber.from(1),
  //     endBlock: BigNumber.from(64),
  //     epochRoot: ethers.utils.randomBytes(32),
  //     validatorSet: [0],
  //   };

  //   const epochId = await childValidatorSet.currentEpochId();
  //   const currentValidatorId = await childValidatorSet.currentValidatorId();

  //   console.log(await childValidatorSet.currentEpochId());
  //   console.log(await stakeManager.lastRewardedEpochId());

  //   const uptime = {
  //     epochId: epochId,
  //     uptimes: [1000000000000],
  //     totalUptime: 0,
  //   };

  //   for (let i = 0; i < currentValidatorId.toNumber() - 2; i++) {
  //     uptime.uptimes.push(1000000000000);
  //   }

  //   const signature = ethers.utils.keccak256(
  //     ethers.utils.defaultAbiCoder.encode(
  //       [
  //         "uint256",
  //         "tuple(uint256 startBlock, uint256 endBlock, bytes32 epochRoot, uint256[] validatorSet)",
  //         "tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)",
  //       ],
  //       [id, epoch, uptime]
  //     )
  //   );

  //   await expect(
  //     systemChildValidatorSet.commitEpoch(id, epoch, uptime, signature)
  //   ).to.be.revertedWith("EPOCH_NOT_COMMITTED");
  // });

  it("Distribute with invalid length", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
    const id = 1;
    const epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [0],
    };

    const epochId = await stakeManager.lastRewardedEpochId();
    const currentValidatorId = await childValidatorSet.currentValidatorId();

    const uptime = {
      epochId: epochId.add(1),
      uptimes: [1000000000000],
      totalUptime: 0,
    };

    for (let i = 0; i < currentValidatorId.toNumber() - 1; i++) {
      uptime.uptimes.push(1000000000000);
    }

    const signature = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint256",
          "tuple(uint256 startBlock, uint256 endBlock, bytes32 epochRoot, uint256[] validatorSet)",
          "tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)",
        ],
        [id, epoch, uptime]
      )
    );

    await expect(
      systemChildValidatorSet.commitEpoch(id, epoch, uptime, signature)
    ).to.be.revertedWith("INVALID_LENGTH");
  });

  it("Distribute with not enough consensus", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
    const id = 1;
    const epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [0],
    };

    const epochId = await stakeManager.lastRewardedEpochId();
    const currentValidatorId = await childValidatorSet.currentValidatorId();

    const uptime = {
      epochId: epochId.add(1),
      uptimes: [1, 1],
      totalUptime: 0,
    };

    const signature = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint256",
          "tuple(uint256 startBlock, uint256 endBlock, bytes32 epochRoot, uint256[] validatorSet)",
          "tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)",
        ],
        [id, epoch, uptime]
      )
    );

    await expect(
      systemChildValidatorSet.commitEpoch(id, epoch, uptime, signature)
    ).to.be.revertedWith("NOT_ENOUGH_CONSENSUS");
  });

  it("Distribute", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
    const id = 1;
    const epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [0],
    };

    const epochId = await stakeManager.lastRewardedEpochId();
    const currentValidatorId = await childValidatorSet.currentValidatorId();

    const uptime = {
      epochId: epochId.add(1),
      uptimes: [1000000000000],
      totalUptime: 0,
    };

    for (let i = 0; i < currentValidatorId.toNumber() - 2; i++) {
      uptime.uptimes.push(1000000000000);
    }

    const signature = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "uint256",
          "tuple(uint256 startBlock, uint256 endBlock, bytes32 epochRoot, uint256[] validatorSet)",
          "tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)",
        ],
        [id, epoch, uptime]
      )
    );

    await systemChildValidatorSet.commitEpoch(id, epoch, uptime, signature);
    const storedEpoch: any = await childValidatorSet.epochs(1);
    expect(storedEpoch.startBlock).to.equal(epoch.startBlock);
    expect(storedEpoch.endBlock).to.equal(epoch.endBlock);
    expect(storedEpoch.epochRoot).to.equal(
      ethers.utils.hexlify(epoch.epochRoot)
    );

    const idToDelegate = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    const delegatorReward = await stakeManager.calculateDelegatorReward(
      idToDelegate.add(1),
      accounts[0].address
    );

    console.log("Reward");
    console.log(delegatorReward);
  });
});
