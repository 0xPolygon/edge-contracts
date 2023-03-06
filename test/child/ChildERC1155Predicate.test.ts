import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildERC1155Predicate,
  ChildERC1155Predicate__factory,
  L2StateSender,
  L2StateSender__factory,
  StateReceiver,
  StateReceiver__factory,
  ChildERC1155,
  ChildERC1155__factory,
  NativeERC20,
  NativeERC20__factory,
} from "../../typechain-types";
import {
  setCode,
  setBalance,
  impersonateAccount,
  stopImpersonatingAccount,
} from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { smock } from "@defi-wonderland/smock";
import { alwaysTrueBytecode } from "../constants";

describe("ChildERC1155Predicate", () => {
  let childERC1155Predicate: ChildERC1155Predicate,
    systemChildERC1155Predicate: ChildERC1155Predicate,
    stateReceiverChildERC1155Predicate: ChildERC1155Predicate,
    l2StateSender: L2StateSender,
    stateReceiver: StateReceiver,
    rootERC1155Predicate: string,
    childERC1155: ChildERC1155,
    nativeERC20: NativeERC20,
    nativeERC20RootToken: string,
    totalSupply: number = 0,
    rootToken: string,
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const L2StateSender: L2StateSender__factory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = await L2StateSender.deploy();

    await l2StateSender.deployed();

    const StateReceiver: StateReceiver__factory = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    rootERC1155Predicate = ethers.Wallet.createRandom().address;

    const ChildERC1155: ChildERC1155__factory = await ethers.getContractFactory("ChildERC1155");
    childERC1155 = await ChildERC1155.deploy();

    await childERC1155.deployed();

    const ChildERC1155Predicate: ChildERC1155Predicate__factory = await ethers.getContractFactory(
      "ChildERC1155Predicate"
    );
    childERC1155Predicate = await ChildERC1155Predicate.deploy();

    await childERC1155Predicate.deployed();

    const NativeERC20: NativeERC20__factory = await ethers.getContractFactory("NativeERC20");

    const tempNativeERC20 = await NativeERC20.deploy();

    await tempNativeERC20.deployed();

    await setCode(
      "0x0000000000000000000000000000000000001010",
      await network.provider.send("eth_getCode", [tempNativeERC20.address])
    ); // Mock genesis NativeERC20 deployment

    nativeERC20 = NativeERC20.attach("0x0000000000000000000000000000000000001010") as NativeERC20;

    await setCode("0x0000000000000000000000000000000000002020", alwaysTrueBytecode); // Mock NATIVE_TRANSFER_PRECOMPILE

    nativeERC20RootToken = ethers.Wallet.createRandom().address;

    impersonateAccount("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    setBalance("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE", "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    systemChildERC1155Predicate = childERC1155Predicate.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );

    impersonateAccount(stateReceiver.address);
    setBalance(stateReceiver.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    stateReceiverChildERC1155Predicate = childERC1155Predicate.connect(await ethers.getSigner(stateReceiver.address));
  });

  it("fail initialization: unauthorized", async () => {
    await expect(
      childERC1155Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    )
      .to.be.revertedWithCustomError(childERC1155Predicate, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("fail bad initialization", async () => {
    await expect(
      systemChildERC1155Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("ChildERC1155Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await systemChildERC1155Predicate.initialize(
      l2StateSender.address,
      stateReceiver.address,
      rootERC1155Predicate,
      childERC1155.address,
      nativeERC20RootToken
    );
    const systemNativeERC20: NativeERC20 = nativeERC20.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );
    await expect(systemNativeERC20.initialize(childERC1155Predicate.address, nativeERC20RootToken, "TEST", "TEST", 18))
      .to.not.be.reverted;
    expect(await childERC1155Predicate.l2StateSender()).to.equal(l2StateSender.address);
    expect(await childERC1155Predicate.stateReceiver()).to.equal(stateReceiver.address);
    expect(await childERC1155Predicate.rootERC1155Predicate()).to.equal(rootERC1155Predicate);
    expect(await childERC1155Predicate.childTokenTemplate()).to.equal(childERC1155.address);
    expect(await childERC1155Predicate.rootTokenToChildToken(nativeERC20RootToken)).to.equal(
      "0x0000000000000000000000000000000000001010"
    );
  });

  it("fail reinitialization", async () => {
    await expect(
      systemChildERC1155Predicate.initialize(
        l2StateSender.address,
        stateReceiver.address,
        rootERC1155Predicate,
        childERC1155.address,
        nativeERC20RootToken
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("deposit tokens from root chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        nativeERC20RootToken,
        accounts[0].address,
        accounts[0].address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const depositTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    stopImpersonatingAccount(stateReceiverChildERC1155Predicate.address);
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC20Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(nativeERC20RootToken);
    expect(depositEvent?.args?.childToken).to.equal(nativeERC20.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("deposit tokens from root chain with different address", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        nativeERC20RootToken,
        accounts[0].address,
        accounts[1].address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const depositTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC20Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(nativeERC20RootToken);
    expect(depositEvent?.args?.childToken).to.equal(nativeERC20.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("map token success", async () => {
    rootToken = ethers.Wallet.createRandom().address;
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    const childTokenAddr = await clonesContract.predictDeterministicAddress(
      childERC1155.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken]),
      childERC1155Predicate.address
    );
    const childToken = childERC1155.attach(childTokenAddr);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST1", "TEST1", 18]
    );
    const mapTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log) => log.event === "L2TokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await childToken.predicate()).to.equal(childERC1155Predicate.address);
    expect(await childToken.rootToken()).to.equal(rootToken);
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
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("map token fail: already mapped", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST1", "TEST1", 18]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("withdraw tokens from child chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * (totalSupply - 10) + 1);
    totalSupply -= randomAmount;
    const depositTx = await childERC1155Predicate.withdraw(nativeERC20.address, 0, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC20Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(nativeERC20RootToken);
    expect(depositEvent?.args?.childToken).to.equal(nativeERC20.address);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw tokens from child chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * (totalSupply - 10) + 1);
    totalSupply -= randomAmount;
    const depositTx = await childERC1155Predicate.withdrawTo(nativeERC20.address, accounts[1].address, 0, 1);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC20Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(nativeERC20RootToken);
    expect(depositEvent?.args?.childToken).to.equal(nativeERC20.address);
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
    await expect(childERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)).to.be.revertedWith(
      "ChildERC1155Predicate: ONLY_STATE_RECEIVER"
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
      stateReceiverChildERC1155Predicate.onStateReceive(0, ethers.Wallet.createRandom().address, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: ONLY_ROOT_PREDICATE");
  });

  it("fail deposit tokens: invalid signature", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.randomBytes(32),
        nativeERC20RootToken,
        nativeERC20.address,
        accounts[0].address,
        accounts[0].address,
        1,
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: INVALID_SIGNATURE");
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
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: not a contract", async () => {
    await expect(childERC1155Predicate.withdraw(ethers.Wallet.createRandom().address, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: NOT_CONTRACT"
    );
  });

  it("fail deposit tokens of unknown child token: wrong deposit token", async () => {
    childERC1155Predicate.connect(await ethers.getSigner(stateReceiver.address));
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        nativeERC20.address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  it("fail deposit tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC1155")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST");
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
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC1155")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST");
    await expect(stateReceiverChildERC1155Predicate.withdraw(childToken.address, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: UNMAPPED_TOKEN"
    );
  });

  // since we fake NativeERC20 here, keep this function last:
  it("fail deposit tokens: mint failed", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        nativeERC20RootToken,
        nativeERC20.address,
        accounts[0].address,
        accounts[0].address,
        1,
      ]
    );
    const fakeNativeERC20 = await smock.fake<NativeERC20>("NativeERC20", {
      address: "0x0000000000000000000000000000000000001010",
    });
    fakeNativeERC20.rootToken.returns(nativeERC20RootToken);
    fakeNativeERC20.predicate.returns(stateReceiverChildERC1155Predicate.address);
    fakeNativeERC20.mint.returns(false);
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: MINT_FAILED");
    fakeNativeERC20.mint.returns();
  });

  it("fail withdraw tokens: burn failed", async () => {
    const fakeNativeERC20 = await smock.fake<NativeERC20>("NativeERC20", {
      address: "0x0000000000000000000000000000000000001010",
    });
    fakeNativeERC20.rootToken.returns(nativeERC20RootToken);
    fakeNativeERC20.predicate.returns(stateReceiverChildERC1155Predicate.address);
    fakeNativeERC20.burn.returns(false);
    await expect(stateReceiverChildERC1155Predicate.withdraw(nativeERC20.address, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: BURN_FAILED"
    );
  });
});
