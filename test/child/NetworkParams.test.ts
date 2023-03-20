import { impersonateAccount, stopImpersonatingAccount, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { NetworkParams } from "../../typechain-types";

describe("NetworkParams", () => {
  let networkParams: NetworkParams,
    accounts: SignerWithAddress[],
    blockGasLimit: number,
    checkpointBlockInterval: number,
    minStake: BigNumber,
    maxValidatorSetSize: number;
  before(async () => {
    accounts = await ethers.getSigners();
  });

  it("fail deployment, invalid input", async () => {
    const networkParamsFactory = await ethers.getContractFactory("NetworkParams");
    await expect(networkParamsFactory.deploy(accounts[0].address, 0, 0, 0, 0)).to.be.revertedWith(
      "NetworkParams: INVALID_INPUT"
    );
  });

  it("deployment success", async () => {
    const networkParamsFactory = await ethers.getContractFactory("NetworkParams");
    blockGasLimit = 10 ** Math.floor(Math.random() + 6);
    checkpointBlockInterval = 2 ** Math.floor(Math.random() * 5 + 10);
    minStake = ethers.utils.parseUnits(String(Math.floor(Math.random() * 20 + 1)));
    maxValidatorSetSize = Math.floor(Math.random() * 20 + 5);
    networkParams = (await networkParamsFactory.deploy(
      accounts[0].address,
      blockGasLimit,
      checkpointBlockInterval,
      minStake,
      maxValidatorSetSize
    )) as NetworkParams;

    await networkParams.deployed();

    expect(await networkParams.blockGasLimit()).to.equal(blockGasLimit);
    expect(await networkParams.checkpointBlockInterval()).to.equal(checkpointBlockInterval);
    expect(await networkParams.minStake()).to.equal(minStake);
    expect(await networkParams.maxValidatorSetSize()).to.equal(maxValidatorSetSize);
  });

  it("set new block gas limit fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewBlockGasLimit(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new block gas limit fail: invalid input", async () => {
    await expect(networkParams.setNewBlockGasLimit(0)).to.be.revertedWith("NetworkParams: INVALID_BLOCK_GAS_LIMIT");
  });

  it("set new block gas limit success", async () => {
    blockGasLimit = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewBlockGasLimit(blockGasLimit);

    expect(await networkParams.blockGasLimit()).to.equal(blockGasLimit);
  });

  it("set new checkpoint block interval fail: invalid input", async () => {
    await expect(networkParams.setNewCheckpointBlockInterval(0)).to.be.revertedWith(
      "NetworkParams: INVALID_CHECKPOINT_INTERVAL"
    );
  });

  it("set new checkpoint block interval success", async () => {
    checkpointBlockInterval = 2 ** Math.floor(Math.random() * 5 + 10);
    await networkParams.setNewCheckpointBlockInterval(checkpointBlockInterval);

    expect(await networkParams.checkpointBlockInterval()).to.equal(checkpointBlockInterval);
  });

  it("set new min stake fail: invalid input", async () => {
    await expect(networkParams.setNewMinStake(0)).to.be.revertedWith("NetworkParams: INVALID_MIN_STAKE");
  });

  it("set new min stake success", async () => {
    minStake = ethers.utils.parseUnits(String(Math.floor(Math.random() * 20 + 1)));
    await networkParams.setNewMinStake(minStake);

    expect(await networkParams.minStake()).to.equal(minStake);
  });

  it("set new max validator set size fail: invalid input", async () => {
    await expect(networkParams.setNewMaxValidatorSetSize(0)).to.be.revertedWith(
      "NetworkParams: INVALID_MAX_VALIDATOR_SET_SIZE"
    );
  });

  it("set new max validator set size success", async () => {
    maxValidatorSetSize = Math.floor(Math.random() * 20 + 5);
    await networkParams.setNewMaxValidatorSetSize(maxValidatorSetSize);

    expect(await networkParams.maxValidatorSetSize()).to.equal(maxValidatorSetSize);
  });
});
