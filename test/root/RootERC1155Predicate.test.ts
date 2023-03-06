import { expect } from "chai";
import { ethers } from "hardhat";
import {
  RootERC1155Predicate,
  RootERC1155Predicate__factory,
  StateSender,
  StateSender__factory,
  ExitHelper,
  ExitHelper__factory,
  ChildERC1155,
  ChildERC1155__factory,
  MockERC1155,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("RootERC1155Predicate", () => {
  let rootERC1155Predicate: RootERC1155Predicate,
    exitHelperRootERC1155Predicate: RootERC1155Predicate,
    stateSender: StateSender,
    exitHelper: ExitHelper,
    childERC1155Predicate: string,
    childTokenTemplate: ChildERC1155,
    rootToken: MockERC1155,
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

    childERC1155Predicate = ethers.Wallet.createRandom().address;

    const ChildERC1155: ChildERC1155__factory = await ethers.getContractFactory("ChildERC1155");
    childTokenTemplate = await ChildERC1155.deploy();

    await childTokenTemplate.deployed();

    const RootERC1155Predicate: RootERC1155Predicate__factory = await ethers.getContractFactory("RootERC1155Predicate");
    rootERC1155Predicate = await RootERC1155Predicate.deploy();

    await rootERC1155Predicate.deployed();

    impersonateAccount(exitHelper.address);
    setBalance(exitHelper.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    exitHelperRootERC1155Predicate = rootERC1155Predicate.connect(await ethers.getSigner(exitHelper.address));
  });

  it("fail bad initialization", async () => {
    await expect(
      rootERC1155Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("RootERC1155Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    const nativeTokenRootAddress = ethers.Wallet.createRandom().address;
    await rootERC1155Predicate.initialize(
      stateSender.address,
      exitHelper.address,
      childERC1155Predicate,
      childTokenTemplate.address,
      nativeTokenRootAddress
    );

    expect(await rootERC1155Predicate.stateSender()).to.equal(stateSender.address);
    expect(await rootERC1155Predicate.exitHelper()).to.equal(exitHelper.address);
    expect(await rootERC1155Predicate.childERC1155Predicate()).to.equal(childERC1155Predicate);
    expect(await rootERC1155Predicate.childTokenTemplate()).to.equal(childTokenTemplate.address);
    expect(await rootERC1155Predicate.rootTokenToChildToken(nativeTokenRootAddress)).to.equal(
      "0x0000000000000000000000000000000000001010"
    );
  });

  it("fail reinitialization", async () => {
    await expect(
      rootERC1155Predicate.initialize(
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
      rootERC1155Predicate.onL2StateReceive(0, "0x0000000000000000000000000000000000000000", "0x00")
    ).to.be.revertedWith("RootERC1155Predicate: ONLY_EXIT_HELPER");
  });

  it("withdraw tokens fail: only child predicate", async () => {
    await expect(
      exitHelperRootERC1155Predicate.onL2StateReceive(0, ethers.Wallet.createRandom().address, "0x00")
    ).to.be.revertedWith("RootERC1155Predicate: ONLY_CHILD_PREDICATE");
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
    await expect(
      exitHelperRootERC1155Predicate.onL2StateReceive(0, childERC1155Predicate, exitData)
    ).to.be.revertedWith("RootERC1155Predicate: INVALID_SIGNATURE");
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
      exitHelperRootERC1155Predicate.onL2StateReceive(0, childERC1155Predicate, exitData)
    ).to.be.revertedWithPanic();
  });

  it("map token success", async () => {
    rootToken = await (await ethers.getContractFactory("MockERC1155")).deploy();
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    const childTokenAddr = await clonesContract.predictDeterministicAddress(
      childTokenTemplate.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken.address]),
      childERC1155Predicate
    );
    const mapTx = await rootERC1155Predicate.mapToken(rootToken.address);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log: any) => log.event === "TokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await rootERC1155Predicate.rootTokenToChildToken(rootToken.address)).to.equal(childTokenAddr);
  });

  it("remap token fail", async () => {
    await expect(rootERC1155Predicate.mapToken(rootToken.address)).to.be.revertedWith(
      "RootERC1155Predicate: ALREADY_MAPPED"
    );
  });

  it("map token fail: zero address", async () => {
    await expect(rootERC1155Predicate.mapToken("0x0000000000000000000000000000000000000000")).to.be.revertedWith(
      "RootERC1155Predicate: INVALID_TOKEN"
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
    await expect(
      exitHelperRootERC1155Predicate.onL2StateReceive(0, childERC1155Predicate, exitData)
    ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
  });

  it("deposit unmapped token: success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    const tempRootToken = await (await ethers.getContractFactory("MockERC1155")).deploy();
    await tempRootToken.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    await tempRootToken.approve(rootERC1155Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootERC1155Predicate.deposit(tempRootToken.address, 0, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC20Deposit");
    const childToken = await rootERC1155Predicate.rootTokenToChildToken(tempRootToken.address);
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
    await rootToken.approve(rootERC1155Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootERC1155Predicate.deposit(rootToken.address, 0, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC20Deposit");
    const childToken = await rootERC1155Predicate.rootTokenToChildToken(rootToken.address);
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
    await rootToken.approve(rootERC1155Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootERC1155Predicate.depositTo(rootToken.address, accounts[1].address, 0, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "ERC20Deposit");
    const childToken = await rootERC1155Predicate.rootTokenToChildToken(rootToken.address);
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
    const withdrawTx = await exitHelperRootERC1155Predicate.onL2StateReceive(0, childERC1155Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC20Withdraw");
    const childToken = await rootERC1155Predicate.rootTokenToChildToken(rootToken.address);
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
    const withdrawTx = await exitHelperRootERC1155Predicate.onL2StateReceive(0, childERC1155Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "ERC20Withdraw");
    const childToken = await rootERC1155Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(withdrawEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });
});
