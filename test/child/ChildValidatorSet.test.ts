import { expect } from "chai";
import * as hre from "hardhat";
import { ethers, upgrades } from "hardhat";
import { Signer, BigNumber } from "ethers";
import * as mcl from "../../ts/mcl";
import { expandMsg } from "../../ts/hashToField";
import { alwaysTrueBytecode, alwaysFalseBytecode } from "../constants";
import { BLS, ChildValidatorSet } from "../../typechain";

const DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

const MAX_COMMISSION = 100;

describe("ChildValidatorSet", () => {
  let bls: BLS,
    rootValidatorSetAddress: string,
    governance: string,
    childValidatorSet: ChildValidatorSet,
    systemChildValidatorSet: ChildValidatorSet,
    stakeManagerValidatorSet: ChildValidatorSet,
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

    await systemChildValidatorSet.initialize(
      epochReward,
      minStake,
      minDelegation,
      [accounts[0].address],
      [[0, 0, 0, 0]],
      [minStake * 2],
      bls.address,
      [0, 0],
      governance
    );

    const currentEpochId = await childValidatorSet.currentEpochId();
    expect(currentEpochId).to.equal(1);

    expect(await childValidatorSet.whitelist(accounts[0].address)).to.equal(true);
    const validator = await childValidatorSet.getValidator(accounts[0].address);
    expect(validator.blsKey.toString()).to.equal("0,0,0,0");
    expect(validator.stake).to.equal(minStake * 2);
    expect(validator.totalStake).to.equal(minStake * 2);
    expect(validator.commission).to.equal(0);
    expect(await childValidatorSet.bls()).to.equal(bls.address);
    expect(await childValidatorSet.message(0)).to.equal(0);
    expect(await childValidatorSet.message(1)).to.equal(0);
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
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002030",
      alwaysTrueBytecode,
    ]);
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
});
