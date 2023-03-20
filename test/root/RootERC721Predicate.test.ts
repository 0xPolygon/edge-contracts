import { expect } from "chai";
import { ethers } from "hardhat";
import {
  RootERC721Predicate,
  RootERC721Predicate__factory,
  StateSender,
  StateSender__factory,
  ExitHelper,
  ExitHelper__factory,
  ChildERC721,
  ChildERC721__factory,
  MockERC721,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("RootERC721Predicate", () => {
  let rootERC721Predicate: RootERC721Predicate,
    exitHelperRootERC721Predicate: RootERC721Predicate,
    stateSender: StateSender,
    exitHelper: ExitHelper,
    childERC721Predicate: string,
    childTokenTemplate: ChildERC721,
    rootToken: MockERC721,
    depositedBatchIds: number[] = [],
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const StateSender: StateSender__factory = await ethers.getContractFactory("StateSender");
    stateSender = await StateSender.deploy();

    await stateSender.deployed();

    const ExitHelper: ExitHelper__factory = await ethers.getContractFactory("ExitHelper");
    exitHelper = await ExitHelper.deploy();

    await exitHelper.deployed();

    childERC721Predicate = ethers.Wallet.createRandom().address;

    const ChildERC721: ChildERC721__factory = await ethers.getContractFactory("ChildERC721");
    childTokenTemplate = await ChildERC721.deploy();

    await childTokenTemplate.deployed();

    const RootERC721Predicate: RootERC721Predicate__factory = await ethers.getContractFactory("RootERC721Predicate");
    rootERC721Predicate = await RootERC721Predicate.deploy();

    await rootERC721Predicate.deployed();

    impersonateAccount(exitHelper.address);
    setBalance(exitHelper.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    exitHelperRootERC721Predicate = rootERC721Predicate.connect(await ethers.getSigner(exitHelper.address));
  });

  it("fail bad initialization", async () => {
    await expect(
      rootERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("RootERC721Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await rootERC721Predicate.initialize(
      stateSender.address,
      exitHelper.address,
      childERC721Predicate,
      childTokenTemplate.address
    );

    expect(await rootERC721Predicate.stateSender()).to.equal(stateSender.address);
    expect(await rootERC721Predicate.exitHelper()).to.equal(exitHelper.address);
    expect(await rootERC721Predicate.childERC721Predicate()).to.equal(childERC721Predicate);
    expect(await rootERC721Predicate.childTokenTemplate()).to.equal(childTokenTemplate.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      rootERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("withdraw tokens fail: only exit helper", async () => {
    await expect(
      rootERC721Predicate.onL2StateReceive(0, "0x0000000000000000000000000000000000000000", "0x00")
    ).to.be.revertedWith("RootERC721Predicate: ONLY_EXIT_HELPER");
  });

  it("withdraw tokens fail: only child predicate", async () => {
    await expect(
      exitHelperRootERC721Predicate.onL2StateReceive(0, ethers.Wallet.createRandom().address, "0x00")
    ).to.be.revertedWith("RootERC721Predicate: ONLY_CHILD_PREDICATE");
  });

  it("withdraw tokens fail: invalid signature", async () => {
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.randomBytes(32),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(exitHelperRootERC721Predicate.onL2StateReceive(0, childERC721Predicate, exitData)).to.be.revertedWith(
      "RootERC721Predicate: INVALID_SIGNATURE"
    );
  });

  it("withdraw tokens fail: unmapped token", async () => {
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW"]),
        ethers.Wallet.createRandom().address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperRootERC721Predicate.onL2StateReceive(0, childERC721Predicate, exitData)
    ).to.be.revertedWithPanic();
  });

  it("map token success", async () => {
    rootToken = await (await ethers.getContractFactory("MockERC721")).deploy();
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    const childTokenAddr = await clonesContract.predictDeterministicAddress(
      childTokenTemplate.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken.address]),
      childERC721Predicate
    );
    const mapTx = await rootERC721Predicate.mapToken(rootToken.address);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log: any) => log.event === "TokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await rootERC721Predicate.rootTokenToChildToken(rootToken.address)).to.equal(childTokenAddr);
  });

  it("remap token fail", async () => {
    await expect(rootERC721Predicate.mapToken(rootToken.address)).to.be.revertedWith(
      "RootERC721Predicate: ALREADY_MAPPED"
    );
  });

  it("map token fail: zero address", async () => {
    await expect(rootERC721Predicate.mapToken("0x0000000000000000000000000000000000000000")).to.be.revertedWith(
      "RootERC721Predicate: INVALID_TOKEN"
    );
  });

  it("withdraw tokens fail: predicate does not have supply", async () => {
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW"]),
        rootToken.address,
        accounts[0].address,
        accounts[0].address,
        1,
      ]
    );
    await expect(exitHelperRootERC721Predicate.onL2StateReceive(0, childERC721Predicate, exitData)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );
  });

  it("deposit unmapped token: success", async () => {
    const tempRootToken = await (await ethers.getContractFactory("MockERC721")).deploy();
    await tempRootToken.mint(accounts[0].address);
    await tempRootToken.approve(rootERC721Predicate.address, 0);
    const depositTx = await rootERC721Predicate.deposit(tempRootToken.address, 0);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC721Deposit");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(tempRootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(tempRootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(0);
  });

  it("deposit tokens to same address: success", async () => {
    await rootToken.mint(accounts[0].address);
    await rootToken.approve(rootERC721Predicate.address, 0);
    const depositTx = await rootERC721Predicate.deposit(rootToken.address, 0);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC721Deposit");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(0);
  });

  it("deposit tokens to different address: success", async () => {
    await rootToken.mint(accounts[0].address);
    await rootToken.approve(rootERC721Predicate.address, 1);
    const depositTx = await rootERC721Predicate.depositTo(rootToken.address, accounts[1].address, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC721Deposit");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.tokenId).to.equal(1);
  });

  it("batch deposit tokens: success", async () => {
    const batchSize = Math.floor(Math.random() * 10 + 2);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      await rootToken.mint(accounts[0].address);
      await rootToken.approve(rootERC721Predicate.address, i + 2);
      depositedBatchIds.push(i + 2);
      receiverArr.push(accounts[1].address);
    }
    const depositTx = await rootERC721Predicate.depositBatch(rootToken.address, receiverArr, depositedBatchIds);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC721DepositBatch");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(depositedBatchIds);
  });

  it("batch deposit unmapped token: success", async () => {
    const tempRootToken = await (await ethers.getContractFactory("MockERC721")).deploy();
    await tempRootToken.mint(accounts[0].address);
    await tempRootToken.approve(rootERC721Predicate.address, 0);
    const depositTx = await rootERC721Predicate.depositBatch(tempRootToken.address, [accounts[0].address], [0]);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC721DepositBatch");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(tempRootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(tempRootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receivers).to.deep.equal([accounts[0].address]);
    expect(depositEvent?.args?.tokenIds).to.deep.equal([0]);
  });

  it("withdraw tokens to same address: success", async () => {
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW"]),
        rootToken.address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    const withdrawTx = await exitHelperRootERC721Predicate.onL2StateReceive(0, childERC721Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC721Withdraw");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.tokenId).to.equal(0);
  });

  it("withdraw tokens to different address: success", async () => {
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW"]),
        rootToken.address,
        accounts[0].address,
        accounts[1].address,
        1,
      ]
    );
    const withdrawTx = await exitHelperRootERC721Predicate.onL2StateReceive(0, childERC721Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC721Withdraw");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(withdrawEvent?.args?.tokenId).to.equal(1);
  });

  it("batch withdraw tokens: success", async () => {
    const batchSize = Math.floor(Math.random() * depositedBatchIds.length + 2);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      receiverArr.push(accounts[2].address);
    }
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW_BATCH"]),
        rootToken.address,
        accounts[1].address,
        receiverArr,
        depositedBatchIds.slice(0, batchSize),
      ]
    );
    const withdrawTx = await exitHelperRootERC721Predicate.onL2StateReceive(0, childERC721Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC721WithdrawBatch");
    const childToken = await rootERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[1].address);
    expect(withdrawEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(withdrawEvent?.args?.tokenIds).to.deep.equal(depositedBatchIds.slice(0, batchSize));
  });
});
