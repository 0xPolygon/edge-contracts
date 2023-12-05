import { impersonateAccount, stopImpersonatingAccount, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { NetworkParams } from "../../typechain-types";

describe("NetworkParams", () => {
  let initParams: NetworkParams.InitParamsStruct;
  let networkParams: NetworkParams, accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    initParams = {
      newOwner: ethers.constants.AddressZero,
      newCheckpointBlockInterval: 0,
      newEpochSize: 0,
      newEpochReward: 0,
      newSprintSize: 0,
      newMinValidatorSetSize: 0,
      newMaxValidatorSetSize: 0,
      newWithdrawalWaitPeriod: 0,
      newBlockTime: 0,
      newBlockTimeDrift: 0,
      newVotingDelay: 0,
      newVotingPeriod: 0,
      newProposalThreshold: 0,
      newBaseFeeChangeDenom: 0,
    };
  });

  it("fail initialization, invalid input", async () => {
    const networkParamsFactory = await ethers.getContractFactory("NetworkParams");
    networkParams = (await networkParamsFactory.deploy()) as NetworkParams;
    await networkParams.deployed();
    await expect(networkParams.initialize(initParams)).to.be.revertedWith("NetworkParams: INVALID_INPUT");
  });

  it("initialization success", async () => {
    initParams.newOwner = accounts[0].address;
    initParams.newCheckpointBlockInterval = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newEpochSize = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newEpochReward = ethers.utils.parseUnits(String(Math.floor(Math.random() * 20 + 1)));
    initParams.newSprintSize = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newMinValidatorSetSize = Math.floor(Math.random() * 20 + 5);
    initParams.newMaxValidatorSetSize = Math.floor(Math.random() * 20 + 5);
    initParams.newWithdrawalWaitPeriod = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newBlockTime = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newBlockTimeDrift = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newVotingDelay = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newVotingPeriod = 2 ** Math.floor(Math.random() * 5 + 10);
    initParams.newProposalThreshold = Math.floor(Math.random() * 100 + 1);
    initParams.newBaseFeeChangeDenom = ethers.utils.parseUnits(String(Math.floor(Math.random() * 20 + 1)));

    await networkParams.initialize(initParams);

    expect(await networkParams.owner()).to.equal(initParams.newOwner);
    expect(await networkParams.checkpointBlockInterval()).to.equal(initParams.newCheckpointBlockInterval);
    expect(await networkParams.epochSize()).to.equal(initParams.newEpochSize);
    expect(await networkParams.epochReward()).to.equal(initParams.newEpochReward);
    expect(await networkParams.sprintSize()).to.equal(initParams.newSprintSize);
    expect(await networkParams.minValidatorSetSize()).to.equal(initParams.newMinValidatorSetSize);
    expect(await networkParams.maxValidatorSetSize()).to.equal(initParams.newMaxValidatorSetSize);
    expect(await networkParams.withdrawalWaitPeriod()).to.equal(initParams.newWithdrawalWaitPeriod);
    expect(await networkParams.blockTime()).to.equal(initParams.newBlockTime);
    expect(await networkParams.blockTimeDrift()).to.equal(initParams.newBlockTimeDrift);
    expect(await networkParams.votingDelay()).to.equal(initParams.newVotingDelay);
    expect(await networkParams.votingPeriod()).to.equal(initParams.newVotingPeriod);
    expect(await networkParams.proposalThreshold()).to.equal(initParams.newProposalThreshold);
    expect(await networkParams.baseFeeChangeDenom()).to.equal(initParams.newBaseFeeChangeDenom);
  });

  it("should throw error on reinitialization", async () => {
    await expect(networkParams.initialize(initParams)).to.be.revertedWith(
      "Initializable: contract is already initialized"
    );
  });

  it("set new checkpoint block interval fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewCheckpointBlockInterval(1)).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new checkpoint block interval fail: invalid input", async () => {
    await expect(networkParams.setNewCheckpointBlockInterval(0)).to.be.revertedWith(
      "NetworkParams: INVALID_CHECKPOINT_INTERVAL"
    );
  });

  it("set new checkpoint block interval success", async () => {
    initParams.newCheckpointBlockInterval = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewCheckpointBlockInterval(initParams.newCheckpointBlockInterval);

    expect(await networkParams.checkpointBlockInterval()).to.equal(initParams.newCheckpointBlockInterval);
  });

  it("set new epoch size fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewEpochSize(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new epoch size fail: invalid input", async () => {
    await expect(networkParams.setNewEpochSize(0)).to.be.revertedWith("NetworkParams: INVALID_EPOCH_SIZE");
  });

  it("set new epoch size success", async () => {
    initParams.newEpochSize = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewEpochSize(initParams.newEpochSize);

    expect(await networkParams.epochSize()).to.equal(initParams.newEpochSize);
  });

  it("set new epoch reward fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewEpochReward(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new epoch reward success", async () => {
    initParams.newEpochReward = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewEpochReward(initParams.newEpochReward);

    expect(await networkParams.epochReward()).to.equal(initParams.newEpochReward);
  });

  it("set new sprint size fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);
    await expect(newNetworkParams.setNewSprintSize(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new sprint size fail: invalid input", async () => {
    await expect(networkParams.setNewSprintSize(0)).to.be.revertedWith("NetworkParams: INVALID_SPRINT_SIZE");
  });

  it("set new sprint size success", async () => {
    initParams.newSprintSize = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewSprintSize(initParams.newSprintSize);

    expect(await networkParams.sprintSize()).to.equal(initParams.newSprintSize);
  });

  it("set new min validator set size fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewMinValidatorSetSize(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new min validator set size fail: invalid input", async () => {
    await expect(networkParams.setNewMinValidatorSetSize(0)).to.be.revertedWith(
      "NetworkParams: INVALID_MIN_VALIDATOR_SET_SIZE"
    );
  });

  it("set new min validator set size success", async () => {
    initParams.newMinValidatorSetSize = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewMinValidatorSetSize(initParams.newMinValidatorSetSize);

    expect(await networkParams.minValidatorSetSize()).to.equal(initParams.newMinValidatorSetSize);
  });

  it("set new max validator set size fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewMaxValidatorSetSize(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new max validator set size fail: invalid input", async () => {
    await expect(networkParams.setNewMaxValidatorSetSize(0)).to.be.revertedWith(
      "NetworkParams: INVALID_MAX_VALIDATOR_SET_SIZE"
    );
  });

  it("set new max validator set size success", async () => {
    initParams.newMaxValidatorSetSize = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewMaxValidatorSetSize(initParams.newMaxValidatorSetSize);

    expect(await networkParams.maxValidatorSetSize()).to.equal(initParams.newMaxValidatorSetSize);
  });

  it("set new withdrawal wait period fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewWithdrawalWaitPeriod(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new withdrawal wait period fail: invalid input", async () => {
    await expect(networkParams.setNewWithdrawalWaitPeriod(0)).to.be.revertedWith(
      "NetworkParams: INVALID_WITHDRAWAL_WAIT_PERIOD"
    );
  });

  it("set new withdrawal wait period success", async () => {
    initParams.newWithdrawalWaitPeriod = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewWithdrawalWaitPeriod(initParams.newWithdrawalWaitPeriod);

    expect(await networkParams.withdrawalWaitPeriod()).to.equal(initParams.newWithdrawalWaitPeriod);
  });

  it("set new block time fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewBlockTime(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new block time fail: invalid input", async () => {
    await expect(networkParams.setNewBlockTime(0)).to.be.revertedWith("NetworkParams: INVALID_BLOCK_TIME");
  });

  it("set new block time success", async () => {
    initParams.newBlockTime = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewBlockTime(initParams.newBlockTime);

    expect(await networkParams.blockTime()).to.equal(initParams.newBlockTime);
  });

  it("set new block time drift fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewBlockTimeDrift(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new block time drift fail: invalid input", async () => {
    await expect(networkParams.setNewBlockTimeDrift(0)).to.be.revertedWith("NetworkParams: INVALID_BLOCK_TIME_DRIFT");
  });

  it("set new block time drift success", async () => {
    initParams.newBlockTimeDrift = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewBlockTimeDrift(initParams.newBlockTimeDrift);

    expect(await networkParams.blockTimeDrift()).to.equal(initParams.newBlockTimeDrift);
  });

  it("set new voting delay fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewVotingDelay(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new voting delay success", async () => {
    initParams.newVotingDelay = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewVotingDelay(initParams.newVotingDelay);

    expect(await networkParams.votingDelay()).to.equal(initParams.newVotingDelay);
  });

  it("set new voting period fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewVotingPeriod(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new voting period fail: invalid input", async () => {
    await expect(networkParams.setNewVotingPeriod(0)).to.be.revertedWith("NetworkParams: INVALID_VOTING_PERIOD");
  });

  it("set new voting period success", async () => {
    initParams.newVotingPeriod = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewVotingPeriod(initParams.newVotingPeriod);

    expect(await networkParams.votingPeriod()).to.equal(initParams.newVotingPeriod);
  });

  it("set new proposal threshold fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewProposalThreshold(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new proposal threshold success", async () => {
    initParams.newProposalThreshold = 10 ** Math.floor(Math.random() + 6);
    await networkParams.setNewProposalThreshold(initParams.newProposalThreshold);

    expect(await networkParams.proposalThreshold()).to.equal(initParams.newProposalThreshold);
  });

  it("set new base fee change denom fail: only owner", async () => {
    await impersonateAccount(accounts[1].address);
    await setBalance(accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const newNetworkParams = networkParams.connect(accounts[1]);

    await expect(newNetworkParams.setNewBaseFeeChangeDenom(1)).to.be.revertedWith("Ownable: caller is not the owner");
    await stopImpersonatingAccount(accounts[1].address);
  });

  it("set new base fee change denom fail: invalid input", async () => {
    await expect(networkParams.setNewBaseFeeChangeDenom(0)).to.be.revertedWith(
      "NetworkParams: INVALID_BASE_FEE_CHANGE_DENOM"
    );
  });

  it("set new base fee change denom success", async () => {
    initParams.newBaseFeeChangeDenom = ethers.utils.parseUnits(String(Math.floor(Math.random() * 20 + 11)));
    await networkParams.setNewBaseFeeChangeDenom(initParams.newBaseFeeChangeDenom);

    expect(await networkParams.baseFeeChangeDenom()).to.equal(initParams.newBaseFeeChangeDenom);
  });
});
