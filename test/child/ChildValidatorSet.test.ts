import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";
import { BLS, ChildValidatorSet, StakeManager } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(
  ethers.utils.hexlify(ethers.utils.randomBytes(32))
);

const MAX_COMMISSION = 100;

describe("ChildValidatorSet", () => {
  let bls: BLS,
    rootValidatorSetAddress: string,
    stakeManager: StakeManager,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    stakeManagerValidatorSet: ChildValidatorSet,
    stateSyncChildValidatorSet: ChildValidatorSet,
    validatorSetSize: number,
    validatorStake: BigNumber,
    epochReward: BigNumber,
    minSelfStake: number,
    minDelegation: number,
    id: number,
    epoch: any,
    uptime: any,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    rootValidatorSetAddress = ethers.Wallet.createRandom().address;

    const StakeManager = await ethers.getContractFactory("StakeManager");
    stakeManager = await StakeManager.deploy();
    await stakeManager.deployed();

    const ChildValidatorSet = await ethers.getContractFactory(
      "ChildValidatorSet"
    );
    childValidatorSet = await ChildValidatorSet.deploy();

    await childValidatorSet.deployed();

    epochReward = ethers.utils.parseEther("0.0000001");
    minSelfStake = 10000;
    minDelegation = 10000;

    await stakeManager.initialize(
      epochReward,
      minSelfStake,
      minDelegation,
      childValidatorSet.address
    );

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
    const systemSigner = await ethers.getSigner(
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"
    );
    const stateSyncSigner = await ethers.getSigner(
      "0x0000000000000000000000000000000000001001"
    );
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
    systemChildValidatorSet = childValidatorSet.connect(systemSigner);
    stateSyncChildValidatorSet = childValidatorSet.connect(stateSyncSigner);
  });
  it("Initialize without system call", async () => {
    await expect(
      childValidatorSet.initialize(
        rootValidatorSetAddress,
        stakeManager.address,
        [],
        [],
        [],
        []
      )
    ).to.be.revertedWith("ONLY_SYSTEMCALL");
  });
  it("Initialize and validate initialization", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 5); // Randomly pick 5-9
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
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await childValidatorSet.validators(i + 1);
      expect(validator._address).to.equal(addresses[i]);
      expect(validator.selfStake).to.equal(validatorStake);
      expect(validator.totalStake).to.equal(validatorStake);
      expect(
        await childValidatorSet.validatorIdByAddress(addresses[i])
      ).to.equal(i + 1);
    }
    // struct array is not available on typechain
    //expect(await childValidatorSet.epochs(1).validatorSet).to.deep.equal(validatorSet);
  });
  it("Attempt reinitialization", async () => {
    await expect(
      systemChildValidatorSet.initialize(
        rootValidatorSetAddress,
        stakeManager.address,
        [],
        [],
        [],
        []
      )
    ).to.be.revertedWith("ALREADY_INITIALIZED");
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
      uptimes: [0],
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
      childValidatorSet.commitEpoch(id, epoch, uptime, signature)
    ).to.be.revertedWith("ONLY_SYSTEMCALL");
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
      uptimes: [0],
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
    ).to.be.revertedWith("UNEXPECTED_EPOCH_ID");
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
      uptimes: [0],
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
    ).to.be.revertedWith("NO_BLOCKS_COMMITTED");
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
      uptimes: [0],
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
    ).to.be.revertedWith("EPOCH_MUST_BE_DIVISIBLE_BY_64");
  });
  it("Commit epoch with invalid signature", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysFalseBytecode,
    ]);

    id = 1;
    const epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [0],
    };

    const epochId = await stakeManager.lastRewardedEpochId();

    const uptime = {
      epochId: epochId.add(1),
      uptimes: [0],
      totalUptime: 0,
    };

    await expect(
      systemChildValidatorSet.commitEpoch(
        id,
        epoch,
        uptime,
        ethers.constants.HashZero
      )
    ).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });
  it("Commit epoch", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
    id = 1;
    epoch = {
      startBlock: BigNumber.from(1),
      endBlock: BigNumber.from(64),
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [0],
    };

    const epochId = await stakeManager.lastRewardedEpochId();
    const currentValidatorId = await childValidatorSet.currentValidatorId();

    uptime = {
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
  });
  it("Commit epoch with old block", async () => {
    const epoch = {
      startBlock: 64,
      endBlock: 127,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    const uptime = {
      epochId: 0,
      uptimes: [0],
      totalUptime: 0,
    };

    await expect(
      systemChildValidatorSet.commitEpoch(
        2,
        epoch,
        uptime,
        ethers.utils.randomBytes(32)
      )
    ).to.be.revertedWith("INVALID_START_BLOCK");
  });
  it("Validator registration state sync from wrong address", async () => {
    const wallet = ethers.Wallet.createRandom();
    await expect(
      childValidatorSet.onStateReceive(
        0,
        wallet.address,
        ethers.utils.randomBytes(1)
      )
    ).to.be.revertedWith("ONLY_STATESYNC");
  });
  it("Validator registration state sync data from wrong root validator set address", async () => {
    const wallet = ethers.Wallet.createRandom();
    await expect(
      stateSyncChildValidatorSet.onStateReceive(
        0,
        wallet.address,
        ethers.utils.randomBytes(1)
      )
    ).to.be.revertedWith("ONLY_ROOT");
  });
  it("Validator registration state sync data with wrong signature", async () => {
    const wallet = ethers.Wallet.createRandom();
    const { pubkey, secret } = mcl.newKeyPair();
    const data = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "uint256[4]"],
      [validatorSetSize, wallet.address, mcl.g2ToHex(pubkey)]
    );
    const encodedData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes"],
      [ethers.utils.randomBytes(32), data]
    );
    await expect(
      stateSyncChildValidatorSet.onStateReceive(
        0,
        rootValidatorSetAddress,
        encodedData
      )
    ).to.be.revertedWith("INVALID_SIGNATURE");
  });
  it("Validator registration state sync full sized data", async () => {
    const wallet = ethers.Wallet.createRandom();
    const { pubkey, secret } = mcl.newKeyPair();
    const MAX_VALIDATOR_SET_SIZE = 500;
    const data = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "uint256[4]"],
      [MAX_VALIDATOR_SET_SIZE + 1, wallet.address, mcl.g2ToHex(pubkey)]
    );
    const encodedData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes"],
      [
        "0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc",
        data,
      ]
    );
    await expect(
      stateSyncChildValidatorSet.onStateReceive(
        0,
        rootValidatorSetAddress,
        encodedData
      )
    ).to.be.revertedWith("VALIDATOR_SET_FULL");
  });
  it("Validator registration state sync", async () => {
    const wallet = ethers.Wallet.createRandom();
    const { pubkey, secret } = mcl.newKeyPair();
    const strippedPubkey = mcl
      .g2ToHex(pubkey)
      .map((elem: any) => ethers.utils.hexValue(elem));
    const data = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "uint256[4]"],
      [validatorSetSize + 1, wallet.address, strippedPubkey]
    );
    const encodedData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes"],
      [
        "0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc",
        data,
      ]
    );
    await stateSyncChildValidatorSet.onStateReceive(
      0,
      rootValidatorSetAddress,
      encodedData
    );
    expect(await childValidatorSet.currentValidatorId()).to.equal(
      validatorSetSize + 1
    );
    const validator = await childValidatorSet.validators(validatorSetSize + 1);
    expect(validator._address).to.equal(wallet.address);
    expect(
      await childValidatorSet.validatorIdByAddress(wallet.address)
    ).to.equal(validatorSetSize + 1);
    //expect(validator.blsKey).to.deep.equal(strippedPubkey);
  });
  it("Get Validator By Id", async () => {
    const addresses = [];
    for (let i = 0; i < validatorSetSize; i++) {
      addresses.push(accounts[i].address);
    }
    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await childValidatorSet.getValidatorById(i + 1);
      expect(validator._address).to.equal(addresses[i]);
      expect(validator.selfStake).to.equal(validatorStake);
      expect(validator.totalStake).to.equal(validatorStake);
    }
  });
  it("Get current validators", async () => {
    const expectedValidatorSet = [];
    for (let i = 0; i < validatorSetSize; i++) {
      expectedValidatorSet.push(BigNumber.from(i + 1));
    }
    expect(await childValidatorSet.getCurrentValidatorSet()).to.deep.equal(
      expectedValidatorSet
    );
  });
  it("Get epoch by block", async () => {
    const storedEpoch = await childValidatorSet.getEpochByBlock(64);
    expect(storedEpoch.startBlock).to.equal(epoch.startBlock);
    expect(storedEpoch.endBlock).to.equal(epoch.endBlock);
    expect(storedEpoch.epochRoot).to.equal(
      ethers.utils.hexlify(epoch.epochRoot)
    );
  });
  it("Get non-existent epoch by block", async () => {
    const storedEpoch = await childValidatorSet.getEpochByBlock(65);
    expect(storedEpoch.startBlock).to.equal(ethers.constants.Zero);
    expect(storedEpoch.endBlock).to.equal(ethers.constants.Zero);
    expect(storedEpoch.epochRoot).to.equal(ethers.constants.HashZero);
  });
  it("Get and set current validators when exceeds active validator set size", async () => {
    const currentValidatorId = await childValidatorSet.currentValidatorId();
    const totalSetSize = Math.floor(Math.random() * 100 + 100); // pick randomly from 100 - 200
    const { pubkey, secret } = mcl.newKeyPair();
    const strippedPubkey = mcl
      .g2ToHex(pubkey)
      .map((elem: any) => ethers.utils.hexValue(elem));
    for (let i = 1; i <= totalSetSize; i++) {
      const wallet = ethers.Wallet.createRandom();
      const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "address", "uint256[4]"],
        [currentValidatorId.add(i), wallet.address, strippedPubkey]
      );
      const encodedData = ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "bytes"],
        [
          "0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc",
          data,
        ]
      );
      await stateSyncChildValidatorSet.onStateReceive(
        0,
        rootValidatorSetAddress,
        encodedData
      );
    }
    epoch = {
      startBlock: 65,
      endBlock: 128,
      epochRoot: ethers.utils.randomBytes(32),
      validatorSet: [],
    };

    const epochId = await stakeManager.lastRewardedEpochId();

    uptime = {
      epochId: epochId.add(1),
      uptimes: [1000000000000],
      totalUptime: 0,
    };

    for (let i = 0; i < currentValidatorId.toNumber() - 2; i++) {
      uptime.uptimes.push(1000000000000);
    }

    await systemChildValidatorSet.commitEpoch(
      2,
      epoch,
      uptime,
      ethers.utils.randomBytes(32)
    ); // commit epoch to update validator set
    const newValidatorSet = await childValidatorSet.getCurrentValidatorSet();
    expect(newValidatorSet).to.have.lengthOf(
      (await childValidatorSet.ACTIVE_VALIDATOR_SET_SIZE()).toNumber()
    );
    let set = new Set();
    newValidatorSet.map((elem: BigNumber) => set.add(elem));
    expect(set).to.have.lengthOf(newValidatorSet.length); // assert each element is unique
  });
  it("Add self stake without stake manager", async () => {
    await expect(childValidatorSet.addSelfStake(0, 100)).to.be.revertedWith(
      "ONLY_STAKE_MANAGER"
    );
  });
  it("Unstake without stake manager", async () => {
    await expect(childValidatorSet.unstake(0, 100)).to.be.revertedWith(
      "ONLY_STAKE_MANAGER"
    );
  });
  it("Add total stake without stake manager", async () => {
    await expect(childValidatorSet.addTotalStake(0, 100)).to.be.revertedWith(
      "ONLY_STAKE_MANAGER"
    );
  });
  it("Add total stake with delegartions locked", async () => {
    await expect(
      stakeManager.delegate(0, false, { value: minDelegation + 1 })
    ).to.be.revertedWith("DELEGATIONS_LOCKED");
  });
  it("Add self stake", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const selfStakeAmount = minSelfStake + 1;
    const beforeSelfStake = (await childValidatorSet.validators(id)).selfStake;

    await stakeManager.selfStake(id, { value: selfStakeAmount });

    const afterSelfStake = (await childValidatorSet.validators(id)).selfStake;
    expect(afterSelfStake.sub(beforeSelfStake)).to.equal(selfStakeAmount);
  });
  it("Add total stake", async () => {
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

    const afterDelegate = (await childValidatorSet.validators(idToDelegate))
      .totalStake;
    expect(afterDelegate.sub(beforeDelegate)).to.equal(delegateAmount);
  });
  it("Unstake", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );

    const unstakeAmount = minSelfStake + 1;
    const beforeSelfStake = (await childValidatorSet.validators(id)).selfStake;

    await stakeManager.unstake(id, unstakeAmount, accounts[0].address);

    const afterSelfStake = (await childValidatorSet.validators(id)).selfStake;
    expect(beforeSelfStake.sub(afterSelfStake)).to.equal(unstakeAmount);
  });
  it("Set commision with wrong validator id", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    const newCommision = MAX_COMMISSION - 1;
    await expect(
      childValidatorSet.setCommission(id.add(1), newCommision)
    ).to.be.revertedWith("ONLY_VALIDATOR");
  });
  it("Set commision with invalid commision", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    const newCommision = MAX_COMMISSION + 1;
    await expect(
      childValidatorSet.setCommission(id, newCommision)
    ).to.be.revertedWith("INVALID_COMMISSION");
  });
  it("Set commision", async () => {
    const id = await childValidatorSet.validatorIdByAddress(
      accounts[0].address
    );
    const newCommision = MAX_COMMISSION - 1;
    await childValidatorSet.setCommission(id, newCommision);
    const validator = await childValidatorSet.validators(id);
    expect(validator.commission).to.equal(newCommision);
  });
  it("Calculate validator power", async () => {
    expect(await childValidatorSet.calculateValidatorPower(1)).to.be.closeTo(
      BigNumber.from(Math.floor((100 * 10 ** 6) / validatorSetSize)),
      1.0
    );
  });
  it("Calculate total stake", async () => {
    expect(await childValidatorSet.calculateTotalStake()).to.equal(
      validatorStake.mul(validatorSetSize).add(minDelegation + 1)
    );
  });
});
