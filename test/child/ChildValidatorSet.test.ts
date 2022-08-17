import { expect } from "chai";
import * as hre from "hardhat";
import { ethers, upgrades } from "hardhat";
import { Signer, BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
// import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";
import { BLS, ChildValidatorSet } from "../../typechain";
import { customError } from "../util";

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

const MAX_COMMISSION = 100;

describe("ChildValidatorSet", () => {
  let bls: BLS,
    rootValidatorSetAddress: string,
    governance: string,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    childValidatorSetValidatorSet: ChildValidatorSet,
    stateSyncChildValidatorSet: ChildValidatorSet,
    validatorSetSize: number,
    validatorStake: BigNumber,
    epochReward: BigNumber,
    minStake: number,
    minDelegation: number,
    id: number,
    epoch: any,
    uptime: any,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    rootValidatorSetAddress = ethers.Wallet.createRandom().address;

    governance = accounts[0].address;
    epochReward = ethers.utils.parseEther("0.0000001");
    minStake = 10000;
    minDelegation = 10000;

    const ChildValidatorSet = await ethers.getContractFactory("ChildValidatorSet");
    childValidatorSet = await ChildValidatorSet.deploy();

    await childValidatorSet.deployed();

    bls = await (await ethers.getContractFactory("BLS")).deploy();
    await bls.deployed();

    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      "0x0000000000000000000000000000000000001001",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x0000000000000000000000000000000000001001"],
    });
    const systemSigner = await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    const stateSyncSigner = await ethers.getSigner("0x0000000000000000000000000000000000001001");
    // await hre.network.provider.send("hardhat_setCode", [
    //   "0x0000000000000000000000000000000000002030",
    //   alwaysTrueBytecode,
    // ]);
    systemChildValidatorSet = childValidatorSet.connect(systemSigner);
    stateSyncChildValidatorSet = childValidatorSet.connect(stateSyncSigner);
  });
  it("Initialize without system call", async () => {
    await expect(
      childValidatorSet.initialize(
        epochReward,
        minStake,
        minDelegation,
        [accounts[0].address],
        [[0, 0, 0, 0]],
        [minStake * 2],
        bls.address,
        [0, 0],
        governance
      )
    ).to.be.revertedWith('Unauthorized("SYSTEMCALL")');
  });
  it("Initialize and validate initialization", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 5); // Randomly pick 5-9
    validatorStake = ethers.utils.parseEther(String(Math.floor(Math.random() * (10000 - 1000) + 1000)));
    const epochValidatorSet = [];

    for (let i = 0; i < validatorSetSize; i++) {
      epochValidatorSet.push(accounts[i].address);
    }

    const messagePoint = mcl.g1ToHex(
      mcl.hashToPoint(ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator")), DOMAIN)
    );

    await systemChildValidatorSet.initialize(
      epochReward,
      minStake,
      minDelegation,
      [accounts[0].address],
      [[0, 0, 0, 0]],
      [minStake * 2],
      bls.address,
      messagePoint,
      governance
    );

    expect(await childValidatorSet.epochReward()).to.equal(epochReward);
    expect(await childValidatorSet.minStake()).to.equal(minStake);
    expect(await childValidatorSet.minDelegation()).to.equal(minDelegation);
    expect(await childValidatorSet.currentEpochId()).to.equal(1);
    expect(await childValidatorSet.owner()).to.equal(accounts[0].address);

    const currentEpochId = await childValidatorSet.currentEpochId();
    expect(currentEpochId).to.equal(1);

    expect(await childValidatorSet.whitelist(accounts[0].address)).to.equal(true);
    const validator = await childValidatorSet.getValidator(accounts[0].address);
    expect(validator.blsKey.toString()).to.equal("0,0,0,0");
    expect(validator.stake).to.equal(minStake * 2);
    expect(validator.totalStake).to.equal(minStake * 2);
    expect(validator.commission).to.equal(0);
    expect(await childValidatorSet.bls()).to.equal(bls.address);
    expect(await childValidatorSet.message(0)).to.equal(messagePoint[0]);
    expect(await childValidatorSet.message(1)).to.equal(messagePoint[1]);
  });
  it("Attempt reinitialization", async () => {
    await expect(
      systemChildValidatorSet.initialize(
        epochReward,
        minStake,
        minDelegation,
        [accounts[0].address],
        [[0, 0, 0, 0]],
        [minStake * 2],
        bls.address,
        [0, 0],
        governance
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });
  it("Commit epoch without system call", async () => {
    id = 0;
    epoch = {
      startBlock: 0,
      endBlock: 0,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    uptime = {
      epochId: 0,
      uptimeData: [{ validator: accounts[0].address, uptime: 0 }],
      totalUptime: 0,
    };

    await expect(childValidatorSet.commitEpoch(id, epoch, uptime)).to.be.revertedWith('Unauthorized("SYSTEMCALL")');
  });
  it("Commit epoch with unexpected id", async () => {
    id = 0;
    epoch = {
      startBlock: 0,
      endBlock: 0,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    uptime = {
      epochId: 0,
      uptimeData: [{ validator: accounts[0].address, uptime: 0 }],
      totalUptime: 0,
    };

    await expect(systemChildValidatorSet.commitEpoch(id, epoch, uptime)).to.be.revertedWith("UNEXPECTED_EPOCH_ID");
  });
  it("Commit epoch with no blocks committed", async () => {
    id = 1;
    epoch = {
      startBlock: 0,
      endBlock: 0,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    uptime = {
      epochId: 0,
      uptimeData: [{ validator: accounts[0].address, uptime: 0 }],
      totalUptime: 0,
    };

    await expect(systemChildValidatorSet.commitEpoch(id, epoch, uptime)).to.be.revertedWith("NO_BLOCKS_COMMITTED");
  });
  it("Commit epoch with incomplete sprint", async () => {
    id = 1;
    epoch = {
      startBlock: 1,
      endBlock: 63,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    uptime = {
      epochId: 0,
      uptimeData: [{ validator: accounts[0].address, uptime: 0 }],
      totalUptime: 0,
    };

    await expect(systemChildValidatorSet.commitEpoch(id, epoch, uptime)).to.be.revertedWith(
      "EPOCH_MUST_BE_DIVISIBLE_BY_64"
    );
  });
  it("Commit epoch", async () => {
    // await hre.network.provider.send("hardhat_setCode", [
    //   "0x0000000000000000000000000000000000002030",
    //   alwaysTrueBytecode,
    // ]);
    id = 1;
    epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [accounts[0].address],
    };

    const currentEpochId = await childValidatorSet.currentEpochId();
    const currentValidatorId = await childValidatorSet.currentEpochId();

    uptime = {
      epochId: currentEpochId,
      uptimeData: [{ validator: accounts[0].address, uptime: 1000000000000 }],
      totalUptime: 0,
    };

    await systemChildValidatorSet.commitEpoch(id, epoch, uptime);
    const storedEpoch: any = await childValidatorSet.epochs(1);
    expect(storedEpoch.startBlock).to.equal(epoch.startBlock);
    expect(storedEpoch.endBlock).to.equal(epoch.endBlock);
    expect(storedEpoch.epochRoot).to.equal(ethers.utils.hexlify(epoch.epochRoot));
  });
  it("Commit epoch with old block", async () => {
    const epoch = {
      startBlock: 64,
      endBlock: 127,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    uptime = {
      epochId: 0,
      uptimeData: [{ validator: accounts[0].address, uptime: 0 }],
      totalUptime: 0,
    };

    await expect(systemChildValidatorSet.commitEpoch(2, epoch, uptime)).to.be.revertedWith("INVALID_START_BLOCK");
  });
  it("Get current validators", async () => {
    expect(await childValidatorSet.getCurrentValidatorSet()).to.deep.equal([accounts[0].address]);
  });
  it("Get epoch by block", async () => {
    const storedEpoch = await childValidatorSet.getEpochByBlock(64);
    expect(storedEpoch.startBlock).to.equal(epoch.startBlock);
    expect(storedEpoch.endBlock).to.equal(epoch.endBlock);
    expect(storedEpoch.epochRoot).to.equal(ethers.utils.hexlify(epoch.epochRoot));
  });
  it("Get non-existent epoch by block", async () => {
    const storedEpoch = await childValidatorSet.getEpochByBlock(65);
    expect(storedEpoch.startBlock).to.equal(ethers.constants.Zero);
    expect(storedEpoch.endBlock).to.equal(ethers.constants.Zero);
    expect(storedEpoch.epochRoot).to.equal(ethers.constants.HashZero);
  });
  it("Get and set current validators when exceeds active validator set size", async () => {
    const currentValidatorId = await childValidatorSet.currentEpochId();

    epoch = {
      startBlock: 65,
      endBlock: 128,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    const currentEpochId = await childValidatorSet.currentEpochId();

    uptime = {
      epochId: currentEpochId,
      uptimeData: [{ validator: accounts[0].address, uptime: 1000000000000 }],
      totalUptime: 0,
    };

    for (let i = 0; i < currentValidatorId.toNumber() - 2; i++) {
      uptime.uptimes.push(1000000000000);
    }

    await systemChildValidatorSet.commitEpoch(2, epoch, uptime); // commit epoch to update validator set
    // const newValidatorSet = await childValidatorSet.getCurrentValidatorSet();
    // expect(newValidatorSet).to.have.lengthOf(
    //   (await childValidatorSet.ACTIVE_VALIDATOR_SET_SIZE()).toNumber()
    // );
    // let set = new Set();
    // newValidatorSet.map((elem: BigNumber) => set.add(elem));
    // expect(set).to.have.lengthOf(newValidatorSet.length); // assert each element is unique
  });

  describe("whitelist", async () => {
    it("only owner should be able to modify whitelist", async () => {
      await expect(childValidatorSet.connect(accounts[1]).addToWhitelist([accounts[1].address])).to.be.revertedWith(
        customError("Unauthorized", "OWNER")
      );
      await expect(
        childValidatorSet.connect(accounts[1]).removeFromWhitelist([accounts[1].address])
      ).to.be.revertedWith(customError("Unauthorized", "OWNER"));
    });
    it("should be able to add to whitelist", async () => {
      await expect(childValidatorSet.addToWhitelist([accounts[1].address, accounts[2].address])).to.not.be.reverted;
      expect(await childValidatorSet.whitelist(accounts[1].address)).to.be.true;
      expect(await childValidatorSet.whitelist(accounts[2].address)).to.be.true;
    });
    it("should be able to remove from whitelist", async () => {
      await expect(childValidatorSet.removeFromWhitelist([accounts[1].address])).to.not.be.reverted;
      expect(await childValidatorSet.whitelist(accounts[1].address)).to.be.false;
    });
  });

  describe("register", async () => {
    it("only whitelisted should be able to register", async () => {
      const message = ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator"));
      const { pubkey, secret } = mcl.newKeyPair();

      const signatures: mcl.Signature[] = [];

      const { signature, messagePoint } = mcl.sign(message, secret, ethers.utils.arrayify(DOMAIN));
      signatures.push(signature);

      const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

      await expect(
        childValidatorSet.connect(accounts[1]).register(aggMessagePoint, mcl.g2ToHex(pubkey))
      ).to.be.revertedWith(customError("Unauthorized", "WHITELIST"));
    });
    it("invalid signature", async () => {
      const { pubkey, secret } = mcl.newKeyPair();
      const message = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(""));
      const signatures: mcl.Signature[] = [];

      const { signature, messagePoint } = mcl.sign(message, secret, ethers.utils.arrayify(DOMAIN));
      signatures.push(signature);

      const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

      await expect(
        childValidatorSet.connect(accounts[2]).register(aggMessagePoint, mcl.g2ToHex(pubkey))
      ).to.be.revertedWith("INVALID_SIGNATURE");
    });
    it("Register", async () => {
      const message = ethers.utils.hexlify(ethers.utils.toUtf8Bytes("polygon-v3-validator"));
      const { pubkey, secret } = mcl.newKeyPair();
      const { signature, messagePoint } = mcl.sign(message, secret, DOMAIN);
      const parsedPubkey = mcl.g2ToHex(pubkey);
      const tx = await childValidatorSet.connect(accounts[2]).register(mcl.g1ToHex(signature), parsedPubkey);
      const receipt = await tx.wait();
      const event = receipt.events?.find((log) => log.event === "NewValidator");
      expect(event?.args?.validator).to.equal(accounts[2].address);
      const parsedEventBlsKey = event?.args?.blsKey.map((elem: BigNumber) => ethers.utils.hexValue(elem.toHexString()));
      const strippedParsedPubkey = parsedPubkey.map((elem) => ethers.utils.hexValue(elem));
      expect(parsedEventBlsKey).to.deep.equal(strippedParsedPubkey);
      expect(await childValidatorSet.whitelist(accounts[2].address)).to.be.false;
      const validator = await childValidatorSet.getValidator(accounts[2].address);
      expect(validator.stake).to.equal(0);
      expect(validator.totalStake).to.equal(0);
      expect(validator.commission).to.equal(0);
      expect(validator.active).to.equal(true);
      const parsedValidatorBlsKey = validator.blsKey.map((elem: BigNumber) =>
        ethers.utils.hexValue(elem.toHexString())
      );
      expect(parsedValidatorBlsKey).to.deep.equal(strippedParsedPubkey);
    });
  });

  describe("stake", async () => {
    it("only whitelisted validators should be able to stake", async () => {
      await expect(childValidatorSet.connect(accounts[1]).stake({ value: minStake })).to.be.revertedWith(
        customError("Unauthorized", "VALIDATOR")
      );
    });

    it("should revert if min amount not reached", async () => {
      await expect(childValidatorSet.connect(accounts[2]).stake({ value: minStake - 1 })).to.be.revertedWith(
        customError("StakeRequirement", "stake", "STAKE_TOO_LOW")
      );
    });

    it("should be able to stake", async () => {
      await expect(childValidatorSet.connect(accounts[2]).stake({ value: minStake * 2 })).to.not.be.reverted;
    });
  });

  describe("queue processing", async () => {
    it("should be able to process queue", async () => {
      let validator = await childValidatorSet.getValidator(accounts[2].address);
      expect(validator.stake).to.equal(0);
      await expect(
        systemChildValidatorSet.commitEpoch(
          3,
          { startBlock: 129, endBlock: 192, epochRoot: ethers.constants.HashZero },
          { epochId: 3, uptimeData: [{ validator: accounts[0].address, uptime: 1 }], totalUptime: 1 }
        )
      ).to.not.be.reverted;
      validator = await childValidatorSet.getValidator(accounts[2].address);
      expect(validator.stake).to.equal(minStake * 2);
    });
  });

  describe("unstake", async () => {
    it("non validators should not be able to unstake due to insufficient balance", async () => {
      await expect(childValidatorSet.connect(accounts[1]).unstake(1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "INSUFFICIENT_BALANCE")
      );
    });

    it("should not be able to exploit int overflow", async () => {
      await expect(childValidatorSet.connect(accounts[1]).unstake(ethers.constants.MaxInt256.add(1))).to.be.reverted;
    });

    it("should not be able to unstake more than staked", async () => {
      await expect(childValidatorSet.unstake(minStake * 2 + 1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "INSUFFICIENT_BALANCE")
      );
    });

    it("should not be able to unstake so that less than minstake is left", async () => {
      await expect(childValidatorSet.unstake(minStake + 1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "STAKE_TOO_LOW")
      );
    });

    it("should be able to partially unstake", async () => {
      await expect(childValidatorSet.connect(accounts[2]).unstake(minStake)).to.not.be.reverted;
    });

    it("should take pending unstakes into account", async () => {
      await expect(childValidatorSet.connect(accounts[2]).unstake(minStake + 1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "INSUFFICIENT_BALANCE")
      );
      await expect(childValidatorSet.connect(accounts[2]).unstake(1)).to.be.revertedWith(
        customError("StakeRequirement", "unstake", "STAKE_TOO_LOW")
      );
    });

    it("should be able to completely unstake", async () => {
      await expect(childValidatorSet.connect(accounts[2]).unstake(minStake)).to.not.be.reverted;
    });

    it("should place in withdrawal queue", async () => {
      expect(await childValidatorSet.pendingWithdrawals(accounts[2].address)).to.equal(minStake * 2);
      expect(await childValidatorSet.withdrawable(accounts[2].address)).to.equal(0);
    });

    it("should reflect balance after queue processing", async () => {
      let validator = await childValidatorSet.getValidator(accounts[2].address);
      expect(validator.stake).to.equal(minStake * 2);
      await expect(
        systemChildValidatorSet.commitEpoch(
          4,
          { startBlock: 193, endBlock: 256, epochRoot: ethers.constants.HashZero },
          { epochId: 4, uptimeData: [{ validator: accounts[0].address, uptime: 1 }], totalUptime: 1 }
        )
      ).to.not.be.reverted;

      // validator = await childValidatorSet.getValidator(accounts[2].address);
      // expect(validator.stake).to.equal(0);
    });
  });

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
