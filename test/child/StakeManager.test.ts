import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { BigNumber, ContractFactory, Signer } from "ethers";
import * as mcl from "../../ts/mcl";
import * as hre from "hardhat";
import { randHex } from "../../ts/utils";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";

import { ChildValidatorSet } from "../../typechain";
import { customError } from "../util";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

describe("StakeManager", () => {
  let rootValidatorSetAddress: string,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    stakeManager: ChildValidatorSet,
    epochReward: BigNumber,
    minStake: number,
    minDelegation: number,
    validatorSetSize: number,
    validatorStake: BigNumber,
    accounts: SignerWithAddress[],
    systemImpersonator: Signer; // we use any so we can access address directly from object

  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    rootValidatorSetAddress = ethers.Wallet.createRandom().address;

    const bls = await (await ethers.getContractFactory("BLS")).deploy();

    epochReward = ethers.utils.parseEther("0.0000001");
    minStake = 10000;
    minDelegation = 10000;

    // await hre.network.provider.send("hardhat_setBalance", [
    //   "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
    //   "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    // ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });

    systemImpersonator = await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");

    const StakeManager = await ethers.getContractFactory("ChildValidatorSet");
    stakeManager = (
      await upgrades.deployProxy(StakeManager.connect(systemImpersonator), [
        epochReward,
        minStake,
        minDelegation,
        [accounts[0].address],
        [[0, 0, 0, 0]],
        [minStake * 2],
        bls.address,
        [0, 0],
        accounts[0].address,
      ])
    ).connect(accounts[0]) as ChildValidatorSet;
    await stakeManager.deployed();

    // const systemSigner = await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    // systemChildValidatorSet = childValidatorSet.connect(systemSigner);
    // systemStakeManager = stakeManager.connect(systemSigner);
  });

  it("initialization", async () => {
    expect(await stakeManager.epochReward()).to.equal(epochReward);
    expect(await stakeManager.minStake()).to.equal(minStake);
    expect(await stakeManager.minDelegation()).to.equal(minDelegation);
    expect(await stakeManager.currentEpochId()).to.equal(1);
    expect(await stakeManager.owner()).to.equal(accounts[0].address);
  });

  describe("whitelist", async () => {
    it("only owner should be able to modify whitelist", async () => {
      await expect(stakeManager.connect(accounts[1]).addToWhitelist([accounts[1].address])).to.be.revertedWith(
        customError("Unauthorized", "OWNER")
      );
      await expect(stakeManager.connect(accounts[1]).removeFromWhitelist([accounts[1].address])).to.be.revertedWith(
        customError("Unauthorized", "OWNER")
      );
    });
    it("should be able to add to whitelist", async () => {
      await expect(stakeManager.addToWhitelist([accounts[1].address, accounts[2].address])).to.not.be.reverted;
      expect(await stakeManager.whitelist(accounts[1].address)).to.be.true;
      expect(await stakeManager.whitelist(accounts[2].address)).to.be.true;
    });
    it("should be able to remove from whitelist", async () => {
      await expect(stakeManager.removeFromWhitelist([accounts[1].address])).to.not.be.reverted;
      expect(await stakeManager.whitelist(accounts[1].address)).to.be.false;
    });
  });

  describe("stake", async () => {
    it("only whitelisted validators should be able to stake", async () => {
      await expect(stakeManager.connect(accounts[1]).stake({ value: minStake })).to.be.revertedWith(
        customError("Unauthorized", "VALIDATOR")
      );
    });

    it("should revert if min amount not reached", async () => {
      await expect(stakeManager.connect(accounts[2]).stake({ value: minStake - 1 })).to.be.revertedWith(
        customError("StakeRequirement", "stake", "STAKE_TOO_LOW")
      );
    });

    it("should be able to stake", async () => {
      await expect(stakeManager.connect(accounts[2]).stake({ value: minStake })).to.not.be.reverted;
    });
  });

  describe("queue processing", async () => {
    it("should be able to process queue", async () => {
      let validator = await stakeManager.getValidator(accounts[2].address);
      expect(validator.stake).to.equal(0);
      await expect(
        stakeManager
          .connect(systemImpersonator)
          .commitEpoch(
            1,
            { startBlock: 1, endBlock: 64, epochRoot: ethers.constants.HashZero },
            { epochId: 1, uptimeData: [{ validator: accounts[0].address, uptime: 1 }], totalUptime: 1 }
          )
      ).to.not.be.reverted;
      validator = await stakeManager.getValidator(accounts[2].address);
      expect(validator.stake).to.equal(minStake);
    });
  });

  describe("unstake", async () => {
    it("non validators should not be able to unstake due to insufficient balance", async () => {
      await expect(stakeManager.connect(accounts[1]).unstake(1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "INSUFFICIENT_BALANCE")
      );
    });

    it("should not be able to exploit int overflow", async () => {
      await expect(stakeManager.connect(accounts[1]).unstake(ethers.constants.MaxInt256.add(1))).to.be.reverted;
    });

    it("should not be able to unstake more than staked", async () => {
      await expect(stakeManager.unstake(minStake * 2 + 1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "INSUFFICIENT_BALANCE")
      );
    });

    it("should not be able to unstake so that less than minstake is left", async () => {
      await expect(stakeManager.unstake(minStake + 1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "STAKE_TOO_LOW")
      );
    });

    it("should be able to partially unstake", async () => {
      await expect(stakeManager.unstake(minStake)).to.not.be.reverted;
    });

    it("should not remove from whitelist after partial unstake", async () => {
      expect(await stakeManager.whitelist(accounts[0].address)).to.be.true;
    });

    it("should take pending unstakes into account", async () => {
      await expect(stakeManager.unstake(minStake + 1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "INSUFFICIENT_BALANCE")
      );
      await expect(stakeManager.unstake(1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "STAKE_TOO_LOW")
      );
    });

    it("should be able to completely unstake", async () => {
      await expect(stakeManager.unstake(minStake)).to.not.be.reverted;
    });

    it("should remove from whitelist after complete unstake", async () => {
      expect(await stakeManager.whitelist(accounts[0].address)).to.be.false;
    });

    it("should place in withdrawal queue", async () => {
      expect(await stakeManager.pendingWithdrawals(accounts[0].address)).to.equal(minStake * 2);
      expect(await stakeManager.withdrawable(accounts[0].address)).to.equal(0);
    });

    it("should reflect balance after queue processing", async () => {
      let validator = await stakeManager.getValidator(accounts[0].address);
      expect(validator.stake).to.equal(minStake * 2);
      await expect(
        stakeManager
          .connect(systemImpersonator)
          .commitEpoch(
            2,
            { startBlock: 65, endBlock: 128, epochRoot: ethers.constants.HashZero },
            { epochId: 2, uptimeData: [{ validator: accounts[0].address, uptime: 1 }], totalUptime: 1 }
          )
      ).to.not.be.reverted;

      validator = await stakeManager.getValidator(accounts[0].address);
      expect(validator.stake).to.equal(0);
    });
  });

  // describe("delegation", async() => {

  // })

  // it("Initialize ChildValidatorSet and validate initialization", async () => {
  //   validatorSetSize = Math.floor(Math.random() * (5 - 1) + 5); // Randomly pick 5-9
  //   // validatorSetSize = 4; // constnatly 4
  //   validatorStake = ethers.utils.parseEther(
  //     String(Math.floor(Math.random() * (10000 - 1000) + 1000))
  //   );
  //   const validatorStakes = Array(validatorSetSize).fill(validatorStake);
  //   const addresses = [];
  //   const pubkeys = [];
  //   const validatorSet = [];
  //   for (let i = 0; i < validatorSetSize; i++) {
  //     const { pubkey, secret } = mcl.newKeyPair();
  //     pubkeys.push(mcl.g2ToHex(pubkey));
  //     addresses.push(accounts[i].address);
  //     validatorSet.push(i + 1);
  //   }

  //   await systemChildValidatorSet.initialize(
  //     rootValidatorSetAddress,
  //     stakeManager.address,
  //     addresses,
  //     pubkeys,
  //     validatorStakes,
  //     validatorSet
  //   );
  //   expect(await childValidatorSet.currentValidatorId()).to.equal(
  //     validatorSetSize
  //   );
  //   expect(await childValidatorSet.stakeManager()).to.equal(
  //     stakeManager.address
  //   );
  //   for (let i = 0; i < validatorSetSize; i++) {
  //     const validator = await childValidatorSet.validators(i + 1);
  //     expect(validator._address).to.equal(addresses[i]);
  //     expect(validator.selfStake).to.equal(validatorStake);
  //     expect(validator.totalStake).to.equal(validatorStake);
  //     expect(
  //       await childValidatorSet.validatorIdByAddress(addresses[i])
  //     ).to.equal(i + 1);
  //   }
  // });

  // it("Delegate less amount than minDelegation", async () => {
  //   const id = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );

  //   const idToDelegate = id.add(1);
  //   const restake = false;

  //   await expect(
  //     stakeManager.delegate(idToDelegate, restake, { value: 100 })
  //   ).to.be.revertedWith("DELEGATION_TOO_LOW");
  // });

  // it("Delegate to invalid id", async () => {
  //   const idToDelegate = await childValidatorSet.currentValidatorId();
  //   const restake = false;

  //   await expect(
  //     stakeManager.delegate(idToDelegate, restake, { value: minDelegation + 1 })
  //   ).to.be.revertedWith("INVALID_VALIDATOR_ID");
  // });

  // it("Delegate for the first time", async () => {
  //   const id = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );

  //   const delegateAmount = minDelegation + 1;
  //   const idToDelegate = id.add(1);
  //   const restake = false;

  //   const beforeDelegate = (await childValidatorSet.validators(idToDelegate))
  //     .totalStake;

  //   await stakeManager.delegate(idToDelegate, restake, {
  //     value: delegateAmount,
  //   });

  //   const delegation = await stakeManager.delegations(
  //     accounts[0].address,
  //     idToDelegate
  //   );
  //   const currentEpochId = await childValidatorSet.currentEpochId();
  //   expect(delegation.epochId).to.equal(currentEpochId);
  //   expect(delegation.amount).to.equal(delegateAmount);

  //   const afterDelegate = (await childValidatorSet.validators(idToDelegate))
  //     .totalStake;
  //   expect(afterDelegate.sub(beforeDelegate)).to.equal(delegateAmount);
  // });

  // it("Delegate again without restake", async () => {
  //   const id = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );

  //   const delegateAmount = minDelegation + 1;
  //   const idToDelegate = id.add(1);
  //   const restake = false;

  //   const beforeDelegate = (await childValidatorSet.validators(idToDelegate))
  //     .totalStake;
  //   const balanceBeforeReDelegate = await ethers.provider.getBalance(
  //     accounts[0].address
  //   );

  //   const txResp = await stakeManager.delegate(idToDelegate, restake, {
  //     value: delegateAmount,
  //   });
  //   const txReceipt = await txResp.wait();
  //   const delegateGas = ethers.BigNumber.from(
  //     txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice)
  //   ).add(10001);

  //   const delegation = await stakeManager.delegations(
  //     accounts[0].address,
  //     idToDelegate
  //   );
  //   const currentEpochId = await childValidatorSet.currentEpochId();
  //   expect(delegation.epochId).to.equal(currentEpochId);
  //   expect(delegation.amount).to.equal(delegateAmount * 2);

  //   const delegatorReward = await stakeManager.calculateDelegatorReward(
  //     idToDelegate,
  //     accounts[0].address
  //   );

  //   const afterDelegate = (await childValidatorSet.validators(idToDelegate))
  //     .totalStake;
  //   const balanceAfterReDelegate = await ethers.provider.getBalance(
  //     accounts[0].address
  //   );

  //   expect(afterDelegate.sub(beforeDelegate)).to.equal(
  //     delegatorReward.add(delegateAmount)
  //   );
  //   expect(
  //     balanceBeforeReDelegate.sub(delegateGas).add(delegatorReward)
  //   ).to.equal(balanceAfterReDelegate);
  // });

  // it("Delegate again with restake", async () => {
  //   const id = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );

  //   const delegateAmount = minDelegation + 1;
  //   const idToDelegate = id.add(1);
  //   const restake = false;

  //   const beforeDelegate = (await childValidatorSet.validators(idToDelegate))
  //     .totalStake;

  //   await stakeManager.delegate(idToDelegate, restake, {
  //     value: delegateAmount,
  //   });

  //   const delegation = await stakeManager.delegations(
  //     accounts[0].address,
  //     idToDelegate
  //   );

  //   const currentEpochId = await childValidatorSet.currentEpochId();
  //   expect(delegation.epochId).to.equal(currentEpochId);

  //   const delegatorReward = await stakeManager.calculateDelegatorReward(
  //     idToDelegate,
  //     accounts[0].address
  //   );
  //   expect(delegation.amount).to.equal(delegatorReward.add(delegateAmount * 3));

  //   const afterDelegate = (await childValidatorSet.validators(idToDelegate))
  //     .totalStake;
  //   expect(afterDelegate.sub(beforeDelegate)).to.equal(
  //     delegatorReward.add(delegateAmount)
  //   );
  // });

  // it("Claim delegatorReward", async () => {
  //   const id = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );

  //   const idToDelegate = id.add(1);

  //   const delegatorReward = await stakeManager.calculateDelegatorReward(
  //     idToDelegate,
  //     accounts[0].address
  //   );

  //   const balanceBeforeReDelegate = await ethers.provider.getBalance(
  //     accounts[0].address
  //   );

  //   const txResp = await stakeManager.claimDelegatorReward(idToDelegate);
  //   const txReceipt = await txResp.wait();
  //   const claimGas = ethers.BigNumber.from(
  //     txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice)
  //   );

  //   const delegation = await stakeManager.delegations(
  //     accounts[0].address,
  //     idToDelegate
  //   );

  //   const balanceAfterReDelegate = await ethers.provider.getBalance(
  //     accounts[0].address
  //   );
  //   expect(balanceBeforeReDelegate.sub(claimGas).add(delegatorReward)).to.equal(
  //     balanceAfterReDelegate
  //   );
  // });

  // it("Distribute without child validator set", async () => {
  //   const uptime = {
  //     epochId: 0,
  //     uptimes: [0],
  //     totalUptime: 0,
  //   };

  //   const signature = ethers.utils.keccak256(
  //     ethers.utils.defaultAbiCoder.encode(
  //       ["tuple(uint256 epochId, uint256[] uptimes, uint256 totalUptime)"],
  //       [uptime]
  //     )
  //   );

  //   await expect(stakeManager.distributeRewards(uptime)).to.be.revertedWith(
  //     "ONLY_VALIDATOR_SET"
  //   );
  // });

  // it("Distribute with not committed epoch", async () => {
  //   await hre.network.provider.send("hardhat_setCode", [
  //     "0x0000000000000000000000000000000000002030",
  //     alwaysTrueBytecode,
  //   ]);

  //   const currentEpochId = await childValidatorSet.currentEpochId();

  //   const id = currentEpochId;
  //   const epoch = {
  //     startBlock: BigNumber.from(1),
  //     endBlock: BigNumber.from(64),
  //     epochRoot: ethers.utils.randomBytes(32),
  //     validatorSet: [0],
  //   };

  //   const currentValidatorId = await childValidatorSet.currentValidatorId();

  //   const uptime = {
  //     epochId: currentEpochId.add(1),
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

  // it("Distribute with invalid length", async () => {
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

  //   const currentEpochId = await childValidatorSet.currentEpochId();
  //   const currentValidatorId = await childValidatorSet.currentValidatorId();

  //   const uptime = {
  //     epochId: currentEpochId,
  //     uptimes: [1000000000000],
  //     totalUptime: 0,
  //   };

  //   for (let i = 0; i < currentValidatorId.toNumber() - 1; i++) {
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
  //   ).to.be.revertedWith("INVALID_LENGTH");
  // });

  // it("Distribute with not enough consensus", async () => {
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

  //   const currentEpochId = await childValidatorSet.currentEpochId();
  //   const currentValidatorId = await childValidatorSet.currentValidatorId();

  //   const uptime = {
  //     epochId: currentEpochId,
  //     uptimes: [1, 1],
  //     totalUptime: 0,
  //   };

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
  //   ).to.be.revertedWith("NOT_ENOUGH_CONSENSUS");
  // });

  // it("Distribute", async () => {
  //   await hre.network.provider.send("hardhat_setCode", [
  //     "0x0000000000000000000000000000000000002030",
  //     alwaysTrueBytecode,
  //   ]);

  //   const epoch = {
  //     startBlock: BigNumber.from(1),
  //     endBlock: BigNumber.from(64),
  //     epochRoot: ethers.utils.randomBytes(32),
  //     validatorSet: [0],
  //   };

  //   const currentEpochId = await childValidatorSet.currentEpochId();
  //   const currentValidatorId = await childValidatorSet.currentValidatorId();

  //   const id = currentEpochId;
  //   const uptime = {
  //     epochId: currentEpochId,
  //     uptimes: [1000000000000],
  //     totalUptime: 100,
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

  //   await systemChildValidatorSet.commitEpoch(id, epoch, uptime, signature);
  //   const storedEpoch: any = await childValidatorSet.epochs(1);
  //   expect(storedEpoch.startBlock).to.equal(epoch.startBlock);
  //   expect(storedEpoch.endBlock).to.equal(epoch.endBlock);
  //   expect(storedEpoch.epochRoot).to.equal(
  //     ethers.utils.hexlify(epoch.epochRoot)
  //   );

  //   const idToDelegate = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );
  //   const delegatorReward = await stakeManager.calculateDelegatorReward(
  //     idToDelegate.add(1),
  //     accounts[0].address
  //   );
  // });

  // it("Unstake", async () => {
  //   const id = await childValidatorSet.validatorIdByAddress(
  //     accounts[0].address
  //   );

  //   const amountToUnstake = minStake + 1;

  //   const selfStakeBefore = await (
  //     await childValidatorSet.validators(id)
  //   ).selfStake;
  //   await stakeManager.unstake(id, amountToUnstake, accounts[0].address);
  //   const selfStakeAfter = await (
  //     await childValidatorSet.validators(id)
  //   ).selfStake;
  //   expect(selfStakeBefore.sub(selfStakeAfter)).to.equal(amountToUnstake);
  // });
});
