import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildMintableERC20Predicate,
  ChildMintableERC20Predicate__factory,
  StateSender,
  StateSender__factory,
  ExitHelper,
  ExitHelper__factory,
  ChildERC20,
  ChildERC20__factory,
  MockERC20,
} from "../../typechain-types";
import { setBalance, impersonateAccount, stopImpersonatingAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { smock } from "@defi-wonderland/smock";
import { alwaysTrueBytecode } from "../constants";

describe("ChildMintableERC20Predicate", () => {
  let childMintableERC20Predicate: ChildMintableERC20Predicate,
    exitHelperChildMintableERC20Predicate: ChildMintableERC20Predicate,
    stateSender: StateSender,
    exitHelper: ExitHelper,
    rootERC20Predicate: string,
    rootToken: string,
    childTokenTemplate: ChildERC20,
    childToken: ChildERC20,
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

    rootERC20Predicate = ethers.Wallet.createRandom().address;
    rootToken = ethers.Wallet.createRandom().address;

    const ChildERC20: ChildERC20__factory = await ethers.getContractFactory("ChildERC20");
    childTokenTemplate = await ChildERC20.deploy();

    await childTokenTemplate.deployed();

    const ChildMintableERC20Predicate: ChildMintableERC20Predicate__factory = await ethers.getContractFactory(
      "ChildMintableERC20Predicate"
    );
    childMintableERC20Predicate = await ChildMintableERC20Predicate.deploy();

    await childMintableERC20Predicate.deployed();

    impersonateAccount(exitHelper.address);
    setBalance(exitHelper.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    exitHelperChildMintableERC20Predicate = childMintableERC20Predicate.connect(
      await ethers.getSigner(exitHelper.address)
    );
  });

  it("fail bad initialization", async () => {
    await expect(
      childMintableERC20Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("ChildMintableERC20Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await childMintableERC20Predicate.initialize(
      stateSender.address,
      exitHelper.address,
      rootERC20Predicate,
      childTokenTemplate.address
    );
    expect(await childMintableERC20Predicate.stateSender()).to.equal(stateSender.address);
    expect(await childMintableERC20Predicate.exitHelper()).to.equal(exitHelper.address);
    expect(await childMintableERC20Predicate.rootERC20Predicate()).to.equal(rootERC20Predicate);
    expect(await childMintableERC20Predicate.childTokenTemplate()).to.equal(childTokenTemplate.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      childMintableERC20Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("map token success", async () => {
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    const childTokenAddr = await clonesContract.predictDeterministicAddress(
      childTokenTemplate.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken]),
      childMintableERC20Predicate.address
    );
    childToken = childTokenTemplate.attach(childTokenAddr);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST1", "TEST1", 18]
    );
    const mapTx = await exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log) => log.event === "MintableTokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await childToken.predicate()).to.equal(childMintableERC20Predicate.address);
    expect(await childToken.rootToken()).to.equal(rootToken);
    expect(await childToken.name()).to.equal("TEST1");
    expect(await childToken.symbol()).to.equal("TEST1");
    expect(await childToken.decimals()).to.equal(18);
  });

  it("map token fail: invalid root token", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [
        ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]),
        "0x0000000000000000000000000000000000000000",
        "TEST1",
        "TEST1",
        18,
      ]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("map token fail: already mapped", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST1", "TEST1", 18]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("deposit tokens from root chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 100);
    totalSupply += randomAmount;
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[0].address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const depositTx = await exitHelperChildMintableERC20Predicate.onL2StateReceive(
      0,
      rootERC20Predicate,
      stateSyncData
    );
    const depositReceipt = await depositTx.wait();
    stopImpersonatingAccount(exitHelperChildMintableERC20Predicate.address);
    const depositEvent = depositReceipt.events?.find((log) => log.event === "MintableERC20Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childToken.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("deposit tokens from root chain with different address", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 100);
    totalSupply += randomAmount;
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[1].address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const depositTx = await exitHelperChildMintableERC20Predicate.onL2StateReceive(
      0,
      rootERC20Predicate,
      stateSyncData
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "MintableERC20Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childToken.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw tokens from child chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * 100 + 1);
    totalSupply -= randomAmount;
    const depositTx = await childMintableERC20Predicate.withdraw(
      childToken.address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "MintableERC20Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childToken.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw tokens from child chain with different address", async () => {
    const randomAmount = Math.floor(Math.random() * 100 + 1);
    totalSupply -= randomAmount;
    const depositTx = await childMintableERC20Predicate.withdrawTo(
      childToken.address,
      accounts[1].address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "MintableERC20Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childToken.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("fail deposit tokens: only state receiver", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(childMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)).to.be.revertedWith(
      "ChildMintableERC20Predicate: ONLY_STATE_RECEIVER"
    );
  });

  it("fail deposit tokens: only root predicate", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, ethers.Wallet.createRandom().address, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC20Predicate: ONLY_ROOT_PREDICATE");
  });

  it("fail deposit tokens: invalid signature", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [ethers.utils.randomBytes(32), rootToken, childToken.address, accounts[0].address, accounts[0].address, 1]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC20Predicate: INVALID_SIGNATURE");
  });

  it("fail deposit tokens of unknown child token: not a contract", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC20Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: not a contract", async () => {
    await expect(childMintableERC20Predicate.withdraw(ethers.Wallet.createRandom().address, 1)).to.be.revertedWith(
      "ChildMintableERC20Predicate: NOT_CONTRACT"
    );
  });

  it("fail deposit tokens of unknown child token: wrong deposit token", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        rootToken,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC20Predicate: UNMAPPED_TOKEN");
  });

  it("fail deposit tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC20")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST", 18);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        childToken.address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC20Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC20")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST", 18);
    await expect(childMintableERC20Predicate.withdraw(childToken.address, 1)).to.be.revertedWith(
      "ChildMintableERC20Predicate: UNMAPPED_TOKEN"
    );
  });

  // since we fake NativeERC20 here, keep this function last:
  it("fail deposit tokens: mint failed", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        childToken.address,
        accounts[0].address,
        accounts[0].address,
        1,
      ]
    );
    const fakeNativeERC20 = await smock.fake<ChildERC20>("ChildERC20", {
      address: childToken.address,
    });
    fakeNativeERC20.rootToken.returns(rootToken);
    fakeNativeERC20.predicate.returns(childMintableERC20Predicate.address);
    fakeNativeERC20.mint.returns(false);
    await expect(
      exitHelperChildMintableERC20Predicate.onL2StateReceive(0, rootERC20Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC20Predicate: MINT_FAILED");
    fakeNativeERC20.mint.returns();
  });

  it("fail withdraw tokens: burn failed", async () => {
    const fakeNativeERC20 = await smock.fake<ChildERC20>("ChildERC20", {
      address: childToken.address,
    });
    fakeNativeERC20.rootToken.returns(rootToken);
    fakeNativeERC20.predicate.returns(childMintableERC20Predicate.address);
    fakeNativeERC20.burn.returns(false);
    await expect(exitHelperChildMintableERC20Predicate.withdraw(childToken.address, 1)).to.be.revertedWith(
      "ChildMintableERC20Predicate: BURN_FAILED"
    );
  });
});
