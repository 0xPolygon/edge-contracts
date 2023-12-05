import { expect } from "chai";
import { ethers } from "hardhat";
import {
  RootMintableERC721Predicate,
  RootMintableERC721Predicate__factory,
  L2StateSender,
  L2StateSender__factory,
  StateReceiver,
  StateReceiver__factory,
  ChildERC721,
  ChildERC721__factory,
  MockERC721,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("RootMintableERC721Predicate", () => {
  let rootMintableERC721Predicate: RootMintableERC721Predicate,
    systemRootMintableERC721Predicate: RootMintableERC721Predicate,
    stateReceiverRootMintableERC721Predicate: RootMintableERC721Predicate,
    l2StateSender: L2StateSender,
    stateReceiver: StateReceiver,
    childERC721Predicate: string,
    childTokenTemplate: ChildERC721,
    rootToken: MockERC721,
    depositedBatchIds: number[] = [],
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const L2StateSender: L2StateSender__factory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = await L2StateSender.deploy();

    await l2StateSender.deployed();

    const StateReceiver: StateReceiver__factory = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    childERC721Predicate = ethers.Wallet.createRandom().address;

    const ChildERC721: ChildERC721__factory = await ethers.getContractFactory("ChildERC721");
    childTokenTemplate = await ChildERC721.deploy();

    await childTokenTemplate.deployed();

    const RootMintableERC721Predicate: RootMintableERC721Predicate__factory = await ethers.getContractFactory(
      "RootMintableERC721Predicate"
    );
    rootMintableERC721Predicate = await RootMintableERC721Predicate.deploy();

    await rootMintableERC721Predicate.deployed();

    impersonateAccount("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    setBalance("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE", "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    systemRootMintableERC721Predicate = rootMintableERC721Predicate.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );

    impersonateAccount(stateReceiver.address);
    setBalance(stateReceiver.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    stateReceiverRootMintableERC721Predicate = rootMintableERC721Predicate.connect(
      await ethers.getSigner(stateReceiver.address)
    );
  });

  it("fail bad initialization", async () => {
    await expect(
      systemRootMintableERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("RootMintableERC721Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await systemRootMintableERC721Predicate.initialize(
      l2StateSender.address,
      stateReceiver.address,
      childERC721Predicate,
      childTokenTemplate.address
    );

    expect(await rootMintableERC721Predicate.l2StateSender()).to.equal(l2StateSender.address);
    expect(await rootMintableERC721Predicate.stateReceiver()).to.equal(stateReceiver.address);
    expect(await rootMintableERC721Predicate.childERC721Predicate()).to.equal(childERC721Predicate);
    expect(await rootMintableERC721Predicate.childTokenTemplate()).to.equal(childTokenTemplate.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      systemRootMintableERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("withdraw tokens fail: only exit helper", async () => {
    await expect(
      rootMintableERC721Predicate.onStateReceive(0, "0x0000000000000000000000000000000000000000", "0x00")
    ).to.be.revertedWith("RootMintableERC721Predicate: ONLY_STATE_RECEIVER");
  });

  it("withdraw tokens fail: only child predicate", async () => {
    await expect(
      stateReceiverRootMintableERC721Predicate.onStateReceive(0, ethers.Wallet.createRandom().address, "0x00")
    ).to.be.revertedWith("RootMintableERC721Predicate: ONLY_CHILD_PREDICATE");
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
      stateReceiverRootMintableERC721Predicate.onStateReceive(0, childERC721Predicate, exitData)
    ).to.be.revertedWith("RootMintableERC721Predicate: INVALID_SIGNATURE");
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
      stateReceiverRootMintableERC721Predicate.onStateReceive(0, childERC721Predicate, exitData)
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
    const mapTx = await rootMintableERC721Predicate.mapToken(rootToken.address);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log: any) => log.event === "L2MintableTokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address)).to.equal(childTokenAddr);
  });

  it("remap token fail", async () => {
    await expect(rootMintableERC721Predicate.mapToken(rootToken.address)).to.be.revertedWith(
      "RootMintableERC721Predicate: ALREADY_MAPPED"
    );
  });

  it("map token fail: zero address", async () => {
    await expect(rootMintableERC721Predicate.mapToken("0x0000000000000000000000000000000000000000")).to.be.revertedWith(
      "RootMintableERC721Predicate: INVALID_TOKEN"
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
      stateReceiverRootMintableERC721Predicate.onStateReceive(0, childERC721Predicate, exitData)
    ).to.be.revertedWith("ERC721: invalid token ID");
  });

  it("deposit unmapped token: success", async () => {
    const tempRootToken = await (await ethers.getContractFactory("MockERC721")).deploy();
    await tempRootToken.mint(accounts[0].address);
    await tempRootToken.approve(rootMintableERC721Predicate.address, 0);
    const depositTx = await rootMintableERC721Predicate.deposit(tempRootToken.address, 0);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC721Deposit");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(tempRootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(tempRootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(0);
  });

  it("deposit tokens to same address: success", async () => {
    await rootToken.mint(accounts[0].address);
    await rootToken.approve(rootMintableERC721Predicate.address, 0);
    const depositTx = await rootMintableERC721Predicate.deposit(rootToken.address, 0);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC721Deposit");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(0);
  });

  it("deposit tokens to different address: success", async () => {
    await rootToken.mint(accounts[0].address);
    await rootToken.approve(rootMintableERC721Predicate.address, 1);
    const depositTx = await rootMintableERC721Predicate.depositTo(rootToken.address, accounts[1].address, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC721Deposit");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address);
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
      await rootToken.approve(rootMintableERC721Predicate.address, i + 2);
      depositedBatchIds.push(i + 2);
      receiverArr.push(accounts[1].address);
    }
    const depositTx = await rootMintableERC721Predicate.depositBatch(rootToken.address, receiverArr, depositedBatchIds);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC721DepositBatch");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(depositEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(depositEvent?.args?.childToken).to.equal(childToken);
    expect(depositEvent?.args?.depositor).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(depositedBatchIds);
  });

  it("batch deposit unmapped token: success", async () => {
    const tempRootToken = await (await ethers.getContractFactory("MockERC721")).deploy();
    await tempRootToken.mint(accounts[0].address);
    await tempRootToken.approve(rootMintableERC721Predicate.address, 0);
    const depositTx = await rootMintableERC721Predicate.depositBatch(tempRootToken.address, [accounts[0].address], [0]);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC721DepositBatch");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(tempRootToken.address);
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
    const withdrawTx = await stateReceiverRootMintableERC721Predicate.onStateReceive(0, childERC721Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "L2MintableERC721Withdraw");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address);
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
    const withdrawTx = await stateReceiverRootMintableERC721Predicate.onStateReceive(0, childERC721Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "L2MintableERC721Withdraw");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address);
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
    const withdrawTx = await stateReceiverRootMintableERC721Predicate.onStateReceive(0, childERC721Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "L2MintableERC721WithdrawBatch");
    const childToken = await rootMintableERC721Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[1].address);
    expect(withdrawEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(withdrawEvent?.args?.tokenIds).to.deep.equal(depositedBatchIds.slice(0, batchSize));
  });
});
