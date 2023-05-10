import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  RootMintableERC20Predicate,
  RootMintableERC20Predicate__factory,
  L2StateSender,
  L2StateSender__factory,
  StateReceiver,
  StateReceiver__factory,
  ChildERC20,
  ChildERC20__factory,
  NativeERC20,
  NativeERC20__factory,
  MockERC20,
} from "../../typechain-types";
import { setCode, setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { alwaysTrueBytecode } from "../constants";

describe("RootMintableERC20Predicate", () => {
  let rootMintableERC20Predicate: RootMintableERC20Predicate,
    systemRootMintableERC20Predicate: RootMintableERC20Predicate,
    stateReceiverRootMintableERC20Predicate: RootMintableERC20Predicate,
    l2StateSender: L2StateSender,
    stateReceiver: StateReceiver,
    childERC20Predicate: string,
    childTokenTemplate: ChildERC20,
    rootToken: MockERC20,
    totalSupply: number = 0,
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const L2StateSender: L2StateSender__factory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = await L2StateSender.deploy();

    await l2StateSender.deployed();

    const StateReceiver: StateReceiver__factory = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    childERC20Predicate = ethers.Wallet.createRandom().address;

    const ChildERC20: ChildERC20__factory = await ethers.getContractFactory("ChildERC20");
    childTokenTemplate = await ChildERC20.deploy();

    await childTokenTemplate.deployed();

    const RootMintableERC20Predicate: RootMintableERC20Predicate__factory = await ethers.getContractFactory(
      "RootMintableERC20Predicate"
    );
    rootMintableERC20Predicate = await RootMintableERC20Predicate.deploy();

    await rootMintableERC20Predicate.deployed();

    const NativeERC20: NativeERC20__factory = await ethers.getContractFactory("NativeERC20");

    const tempNativeERC20 = await NativeERC20.deploy();

    await tempNativeERC20.deployed();

    await setCode(
      "0x0000000000000000000000000000000000001010",
      await network.provider.send("eth_getCode", [tempNativeERC20.address])
    ); // Mock genesis NativeERC20 deployment

    NativeERC20.attach("0x0000000000000000000000000000000000001010") as NativeERC20;

    await setCode("0x0000000000000000000000000000000000002020", alwaysTrueBytecode); // Mock NATIVE_TRANSFER_PRECOMPILE

    impersonateAccount("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    setBalance("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE", "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    systemRootMintableERC20Predicate = rootMintableERC20Predicate.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );

    impersonateAccount(stateReceiver.address);
    setBalance(stateReceiver.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    stateReceiverRootMintableERC20Predicate = rootMintableERC20Predicate.connect(
      await ethers.getSigner(stateReceiver.address)
    );
  });

  it("fail bad initialization", async () => {
    await expect(
      systemRootMintableERC20Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("RootMintableERC20Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await systemRootMintableERC20Predicate.initialize(
      l2StateSender.address,
      stateReceiver.address,
      childERC20Predicate,
      childTokenTemplate.address
    );

    expect(await rootMintableERC20Predicate.l2StateSender()).to.equal(l2StateSender.address);
    expect(await rootMintableERC20Predicate.stateReceiver()).to.equal(stateReceiver.address);
    expect(await rootMintableERC20Predicate.childERC20Predicate()).to.equal(childERC20Predicate);
    expect(await rootMintableERC20Predicate.childTokenTemplate()).to.equal(childTokenTemplate.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      systemRootMintableERC20Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("withdraw tokens fail: only exit helper", async () => {
    await expect(
      rootMintableERC20Predicate.onStateReceive(0, "0x0000000000000000000000000000000000000000", "0x00")
    ).to.be.revertedWith("RootMintableERC20Predicate: ONLY_STATE_RECEIVER");
  });

  it("withdraw tokens fail: only child predicate", async () => {
    await expect(
      stateReceiverRootMintableERC20Predicate.onStateReceive(0, ethers.Wallet.createRandom().address, "0x00")
    ).to.be.revertedWith("RootMintableERC20Predicate: ONLY_CHILD_PREDICATE");
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
      stateReceiverRootMintableERC20Predicate.onStateReceive(0, childERC20Predicate, exitData)
    ).to.be.revertedWith("RootMintableERC20Predicate: INVALID_SIGNATURE");
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
      stateReceiverRootMintableERC20Predicate.onStateReceive(0, childERC20Predicate, exitData)
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
    const mapTx = await rootMintableERC20Predicate.mapToken(rootToken.address);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log: any) => log.event === "L2MintableTokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await rootMintableERC20Predicate.rootTokenToChildToken(rootToken.address)).to.equal(childTokenAddr);
  });

  it("remap token fail", async () => {
    await expect(rootMintableERC20Predicate.mapToken(rootToken.address)).to.be.revertedWith(
      "RootMintableERC20Predicate: ALREADY_MAPPED"
    );
  });

  it("map token fail: zero address", async () => {
    await expect(rootMintableERC20Predicate.mapToken("0x0000000000000000000000000000000000000000")).to.be.revertedWith(
      "RootMintableERC20Predicate: INVALID_TOKEN"
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
      stateReceiverRootMintableERC20Predicate.onStateReceive(0, childERC20Predicate, exitData)
    ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
  });

  it("deposit unmapped token: success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    const tempRootToken = await (await ethers.getContractFactory("MockERC20")).deploy();
    await tempRootToken.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    await tempRootToken.approve(rootMintableERC20Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootMintableERC20Predicate.deposit(
      tempRootToken.address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC20Deposit");
    const childToken = await rootMintableERC20Predicate.rootTokenToChildToken(tempRootToken.address);
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
    await rootToken.approve(rootMintableERC20Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootMintableERC20Predicate.deposit(
      rootToken.address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC20Deposit");
    const childToken = await rootMintableERC20Predicate.rootTokenToChildToken(rootToken.address);
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
    await rootToken.approve(rootMintableERC20Predicate.address, ethers.utils.parseUnits(String(randomAmount)));
    const depositTx = await rootMintableERC20Predicate.depositTo(
      rootToken.address,
      accounts[1].address,
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt?.events?.find((log: any) => log.event === "L2MintableERC20Deposit");
    const childToken = await rootMintableERC20Predicate.rootTokenToChildToken(rootToken.address);
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
    const withdrawTx = await stateReceiverRootMintableERC20Predicate.onStateReceive(0, childERC20Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "L2MintableERC20Withdraw");
    const childToken = await rootMintableERC20Predicate.rootTokenToChildToken(rootToken.address);
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
    const withdrawTx = await stateReceiverRootMintableERC20Predicate.onStateReceive(0, childERC20Predicate, exitData);
    const withdrawReceipt = await withdrawTx.wait();
    const withdrawEvent = withdrawReceipt?.events?.find((log: any) => log.event === "L2MintableERC20Withdraw");
    const childToken = await rootMintableERC20Predicate.rootTokenToChildToken(rootToken.address);
    expect(withdrawEvent?.args?.rootToken).to.equal(rootToken.address);
    expect(withdrawEvent?.args?.childToken).to.equal(childToken);
    expect(withdrawEvent?.args?.withdrawer).to.equal(accounts[0].address);
    expect(withdrawEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(withdrawEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });
});
