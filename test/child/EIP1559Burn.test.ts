import { setCode, impersonateAccount, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import * as hre from "hardhat";
import { ethers, network } from "hardhat";
import {
  L2StateSender,
  L2StateSender__factory,
  StateReceiver,
  StateReceiver__factory,
  ChildERC20,
  ChildERC20__factory,
  ChildERC20Predicate,
  ChildERC20Predicate__factory,
  NativeERC20,
  NativeERC20__factory,
  EIP1559Burn,
  EIP1559Burn__factory,
} from "../../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { alwaysTrueBytecode } from "../constants";

describe("EIP1559Burn", () => {
  let eip1559Burn: EIP1559Burn,
    l2StateSender: L2StateSender,
    stateReceiver: StateReceiver,
    childERC20: ChildERC20,
    childERC20Predicate: ChildERC20Predicate,
    systemChildERC20Predicate: ChildERC20Predicate,
    stateReceiverChildERC20Predicate: ChildERC20Predicate,
    nativeERC20: NativeERC20,
    rootERC20Predicate: string,
    nativeERC20RootToken: string,
    burnDestination: string,
    totalSupply: number,
    accounts: SignerWithAddress[];
  before(async () => {
    // force reset network to clear old storage
    await hre.network.provider.send("hardhat_reset");
    accounts = await ethers.getSigners();

    const L2StateSender: L2StateSender__factory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = await L2StateSender.deploy();

    await l2StateSender.deployed();

    const StateReceiver: StateReceiver__factory = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    rootERC20Predicate = ethers.Wallet.createRandom().address;

    const ChildERC20: ChildERC20__factory = await ethers.getContractFactory("ChildERC20");
    childERC20 = await ChildERC20.deploy();

    await childERC20.deployed();

    const ChildERC20Predicate: ChildERC20Predicate__factory = await ethers.getContractFactory("ChildERC20Predicate");

    childERC20Predicate = await ChildERC20Predicate.deploy();

    await childERC20Predicate.deployed();

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

    systemChildERC20Predicate = childERC20Predicate.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );

    await systemChildERC20Predicate.initialize(
      l2StateSender.address,
      stateReceiver.address,
      rootERC20Predicate,
      childERC20.address,
      nativeERC20RootToken
    );

    impersonateAccount(stateReceiver.address);
    setBalance(stateReceiver.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    stateReceiverChildERC20Predicate = childERC20Predicate.connect(await ethers.getSigner(stateReceiver.address));

    const EIP1559Burn: EIP1559Burn__factory = await ethers.getContractFactory("EIP1559Burn");
    eip1559Burn = await EIP1559Burn.deploy();

    await eip1559Burn.deployed();

    totalSupply = 0;
  });

  it("bad initialization", async () => {
    await expect(eip1559Burn.initialize(ethers.constants.AddressZero, ethers.constants.AddressZero)).to.be.revertedWith(
      "EIP1559Burn: BAD_INITIALIZATION"
    );
  });

  it("withdraw fail", async () => {
    await expect(eip1559Burn.withdraw()).to.be.revertedWith("EIP1559Burn: UNINITIALIZED");
  });

  it("initialize and validate initialization", async () => {
    burnDestination = ethers.Wallet.createRandom().address;
    await expect(eip1559Burn.initialize(childERC20Predicate.address, burnDestination)).to.not.be.reverted;

    expect(await eip1559Burn.childERC20Predicate()).to.equal(childERC20Predicate.address);
    expect(await eip1559Burn.burnDestination()).to.equal(burnDestination);
  });

  it("fail reinitialization", async () => {
    await expect(eip1559Burn.initialize(ethers.constants.AddressZero, ethers.constants.AddressZero)).to.be.revertedWith(
      "Initializable: contract is already initialized"
    );
  });

  it("mint tokens and transfer", async () => {
    const systemNativeERC20: NativeERC20 = nativeERC20.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );
    await expect(systemNativeERC20.initialize(childERC20Predicate.address, nativeERC20RootToken, "TEST", "TEST", 18)).to
      .not.be.reverted;
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        nativeERC20RootToken,
        accounts[0].address,
        eip1559Burn.address,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    await expect(stateReceiverChildERC20Predicate.onStateReceive(0, rootERC20Predicate, stateSyncData)).to.not.be
      .reverted;
    setBalance(eip1559Burn.address, ethers.utils.parseUnits(String(randomAmount)));
    expect(await nativeERC20.balanceOf(eip1559Burn.address)).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw success", async () => {
    await expect(eip1559Burn.withdraw())
      .to.emit(eip1559Burn, "NativeTokenBurnt")
      .withArgs(accounts[0].address, await nativeERC20.balanceOf(eip1559Burn.address));
    expect(await nativeERC20.totalSupply()).to.equal(0);
  });
});
