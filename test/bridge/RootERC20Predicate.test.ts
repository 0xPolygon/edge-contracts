import { expect } from "chai";
import { ethers } from "hardhat";
import {
  RootERC20Predicate,
  RootERC20Predicate__factory,
  StateSender,
  StateSender__factory,
  ExitHelper,
  ExitHelper__factory,
  ChildERC20,
  ChildERC20__factory,
  MockERC20,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("RootERC20Predicate", () => {
  let rootERC20Predicate: RootERC20Predicate,
    exitHelperRootERC20Predicate: RootERC20Predicate,
    stateSender: StateSender,
    exitHelper: ExitHelper,
    childERC20Predicate: string,
    childTokenTemplate: ChildERC20,
    rootToken: MockERC20,
    totalSupply: number = 0,
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const StateSender: StateSender__factory = await ethers.getContractFactory("StateSender");
    stateSender = await StateSender.deploy();

    await stateSender.deployed();

    const ExitHelper: ExitHelper__factory = await ethers.getContractFactory("ExitHelper");
    exitHelper = await ExitHelper.deploy();

    await exitHelper.deployed();

    childERC20Predicate = ethers.Wallet.createRandom().address;

    const ChildERC20: ChildERC20__factory = await ethers.getContractFactory("ChildERC20");
    childTokenTemplate = await ChildERC20.deploy();

    await childTokenTemplate.deployed();

    const RootERC20Predicate: RootERC20Predicate__factory = await ethers.getContractFactory("RootERC20Predicate");
    rootERC20Predicate = await RootERC20Predicate.deploy();

    await rootERC20Predicate.deployed();

    impersonateAccount(exitHelper.address);
    setBalance(exitHelper.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    exitHelperRootERC20Predicate = rootERC20Predicate.connect(await ethers.getSigner(exitHelper.address));
  });

  it("fail bad initialization", async () => {
    await expect(
      rootERC20Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("RootERC20Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    const nativeTokenRootAddress = ethers.Wallet.createRandom().address;
    await rootERC20Predicate.initialize(
      stateSender.address,
      exitHelper.address,
      childERC20Predicate,
      childTokenTemplate.address,
      nativeTokenRootAddress
    );

    expect(await rootERC20Predicate.stateSender()).to.equal(stateSender.address);
    expect(await rootERC20Predicate.exitHelper()).to.equal(exitHelper.address);
    expect(await rootERC20Predicate.childERC20Predicate()).to.equal(childERC20Predicate);
    expect(await rootERC20Predicate.childTokenTemplate()).to.equal(childTokenTemplate.address);
    expect(await rootERC20Predicate.rootTokenToChildToken(nativeTokenRootAddress)).to.equal(
      "0x0000000000000000000000000000000000001010"
    );
  });

  it("fail reinitialization", async () => {
    await expect(
      rootERC20Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("withdraw tokens fail: only exit helper", async () => {
    await expect(
      rootERC20Predicate.onL2StateReceive(0, "0x0000000000000000000000000000000000000000", "0x00")
    ).to.be.revertedWith("RootERC20Predicate: ONLY_EXIT_HELPER");
  });

  it("withdraw tokens fail: only child predicate", async () => {
    await expect(
      exitHelperRootERC20Predicate.onL2StateReceive(0, ethers.Wallet.createRandom().address, "0x00")
    ).to.be.revertedWith("RootERC20Predicate: ONLY_CHILD_PREDICATE");
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
    await expect(exitHelperRootERC20Predicate.onL2StateReceive(0, childERC20Predicate, exitData)).to.be.revertedWith(
      "RootERC20Predicate: INVALID_SIGNATURE"
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
      exitHelperRootERC20Predicate.onL2StateReceive(0, childERC20Predicate, exitData)
    ).to.be.revertedWithPanic();
  });

  it("map token success", async () => {
    rootToken = await (await ethers.getContractFactory("MockERC20")).deploy();
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    const childTokenAddr = await clonesContract.predictDeterministicAddress(
      childTokenTemplate.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken.address]),
      childERC20Predicate
    );
    const mapTx = await rootERC20Predicate.mapToken(rootToken.address);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log: any) => log.event === "TokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await rootERC20Predicate.rootTokenToChildToken(rootToken.address)).to.equal(childTokenAddr);
  });

  it("remap token fail", async () => {
    await expect(rootERC20Predicate.mapToken(rootToken.address)).to.be.revertedWith(
      "RootERC20Predicate: ALREADY_MAPPED"
    );
  });

  it("map token fail: zero address", async () => {
    await expect(rootERC20Predicate.mapToken("0x0000000000000000000000000000000000000000")).to.be.revertedWith(
      "RootERC20Predicate: INVALID_TOKEN"
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
    await expect(exitHelperRootERC20Predicate.onL2StateReceive(0, childERC20Predicate, exitData)).to.be.revertedWith(
      "ERC20: transfer amount exceeds balance"
    );
  });

  it("deposit unmapped token: success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    const tempRootToken = await (await ethers.getContractFactory("MockERC20")).deploy();
    await tempRootToken.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    await tempRootToken.approve(rootERC20Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootERC20Predicate.deposit(
      tempRootToken.address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC20Deposit");
    const childToken = await rootERC20Predicate.rootTokenToChildToken(tempRootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(tempRootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("deposit tokens to same address: success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    await rootToken.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    await rootToken.approve(rootERC20Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootERC20Predicate.deposit(
      rootToken.address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC20Deposit");
    const childToken = await rootERC20Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("deposit tokens to different address: success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    await rootToken.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    await rootToken.approve(rootERC20Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootERC20Predicate.depositTo(
      rootToken.address,
      accounts[1].address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC20Deposit");
    const childToken = await rootERC20Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw tokens to same address: success", async () => {
    const randomAmount = Math.floor(Math.random() * totalSupply + 1);
    totalSupply -= randomAmount;
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW"]),
        rootToken.address,
        accounts[0].address,
        accounts[0].address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const withdrawTx = await exitHelperRootERC20Predicate.onL2StateReceive(0, childERC20Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC20Withdraw");
    const childToken = await rootERC20Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw tokens to different address: success", async () => {
    const randomAmount = Math.floor(Math.random() * totalSupply + 1);
    totalSupply -= randomAmount;
    const exitData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["WITHDRAW"]),
        rootToken.address,
        accounts[0].address,
        accounts[1].address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const withdrawTx = await exitHelperRootERC20Predicate.onL2StateReceive(0, childERC20Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC20Withdraw");
    const childToken = await rootERC20Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(withdrawEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });
});
