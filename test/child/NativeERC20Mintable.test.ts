import { expect } from "chai";
import { BigNumber } from "ethers";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import {
  NativeERC20Mintable,
  NativeERC20Mintable__factory,
  ChildERC20Predicate,
  ChildERC20Predicate__factory,
  MockNativeERC20Transfer,
  MockNativeERC20Transfer__factory,
} from "../../typechain-types";
import { alwaysFalseBytecode, alwaysRevertBytecode, alwaysTrueBytecode } from "../constants";

describe("NativeERC20Mintable", () => {
  let nativeERC20: NativeERC20Mintable,
    systemNativeERC20: NativeERC20Mintable,
    predicateNativeERC20: NativeERC20Mintable,
    minterNativeERC20: NativeERC20Mintable,
    zeroAddressNativeERC20: NativeERC20Mintable,
    childERC20Predicate: ChildERC20Predicate,
    mockNativeERC20Transfer: MockNativeERC20Transfer,
    balance: BigNumber,
    totalSupply: number,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    // force reset network to clear old storage
    await hre.network.provider.send("hardhat_reset");
    accounts = await ethers.getSigners();

    const ChildERC20Predicate: ChildERC20Predicate__factory = await ethers.getContractFactory("ChildERC20Predicate");
    childERC20Predicate = await ChildERC20Predicate.deploy();

    await childERC20Predicate.deployed();

    const NativeERC20: NativeERC20Mintable__factory = await ethers.getContractFactory("NativeERC20Mintable");
    nativeERC20 = await NativeERC20.deploy();

    await nativeERC20.deployed();

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });

    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE", "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"],
    });

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000001010",
      await hre.network.provider.send("eth_getCode", [nativeERC20.address]), // NativeERC20 genesis contract
    ]);

    nativeERC20 = nativeERC20.attach("0x0000000000000000000000000000000000001010");

    systemNativeERC20 = nativeERC20.connect(await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"));

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode, // native transfer pre-compile
    ]);

    const MockNativeERC20Transfer: MockNativeERC20Transfer__factory = await ethers.getContractFactory(
      "MockNativeERC20Transfer"
    );
    mockNativeERC20Transfer = await MockNativeERC20Transfer.deploy();

    await mockNativeERC20Transfer.deployed();

    totalSupply = 0;
  });

  it("fail initialization: systemcall", async () => {
    await expect(
      nativeERC20.initialize(
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        "TEST",
        "TEST",
        18
      )
    )
      .to.be.revertedWithCustomError(nativeERC20, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("fail initialization: systemcall", async () => {
    await expect(
      nativeERC20.initialize(
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        "TEST",
        "TEST",
        18
      )
    )
      .to.be.revertedWithCustomError(nativeERC20, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("fail initialization: invalid owner", async () => {
    await expect(
      systemNativeERC20.initialize(
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        "TEST",
        "TEST",
        18
      )
    ).to.be.revertedWith("NativeERC20: Invalid owner address");
  });

  it("initialize and validate initialization", async () => {
    await expect(
      systemNativeERC20.initialize(
        childERC20Predicate.address,
        accounts[1].address,
        ethers.constants.AddressZero,
        "TEST",
        "TEST",
        18
      )
    ).to.not.be.reverted;
    expect(await nativeERC20.name()).to.equal("TEST");
    expect(await nativeERC20.symbol()).to.equal("TEST");
    expect(await nativeERC20.decimals()).to.equal(18);
    expect(await nativeERC20.totalSupply()).to.equal(0);
    expect(await nativeERC20.predicate()).to.equal(childERC20Predicate.address);
    expect(await nativeERC20.rootToken()).to.equal(ethers.constants.AddressZero);
    expect(await nativeERC20.owner()).to.equal(accounts[1].address);
  });

  it("reinitialization fail", async () => {
    await expect(
      nativeERC20.initialize(
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        "",
        "",
        0
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("mint tokens fail: only predicate", async () => {
    await expect(nativeERC20.mint(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "NativeERC20: Only predicate or owner can call"
    );
  });

  it("mint tokens fail: zero address", async () => {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [childERC20Predicate.address],
    });
    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: [childERC20Predicate.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"],
    });
    predicateNativeERC20 = nativeERC20.connect(await ethers.getSigner(childERC20Predicate.address));
    await expect(predicateNativeERC20.mint(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: mint to the zero address"
    );
  });

  it("mint tokens fail: pre-compile call failed", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysFalseBytecode,
    ]);
    await expect(predicateNativeERC20.mint(ethers.Wallet.createRandom().address, 1)).to.be.revertedWith(
      "PRECOMPILE_CALL_FAILED"
    );
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode,
    ]);
  });

  it("mint tokens", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    await predicateNativeERC20.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[0].address,
      ethers.utils.hexStripZeros(ethers.utils.parseUnits(String(randomAmount)).toHexString()),
    ]);
    expect(await nativeERC20.totalSupply()).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("mint tokens from minter", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    minterNativeERC20 = nativeERC20.connect(await ethers.getSigner(accounts[1].address));
    await minterNativeERC20.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    const prevBalance = await nativeERC20.balanceOf(accounts[0].address);
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[0].address,
      ethers.utils.hexStripZeros(prevBalance.add(ethers.utils.parseUnits(String(randomAmount))).toHexString()),
    ]);
    expect(await nativeERC20.totalSupply()).to.equal(ethers.utils.parseUnits(String(totalSupply)));
  });

  it("balanceOf", async () => {
    expect(await nativeERC20.balanceOf(accounts[0].address)).to.equal(ethers.utils.parseUnits(String(totalSupply)));
  });

  it("transfer fail: pre-compile returns false", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysFalseBytecode,
    ]);
    await expect(nativeERC20.transfer(accounts[1].address, 1)).to.be.revertedWith("PRECOMPILE_CALL_FAILED");
  });

  it("transfer fail: pre-compile reverts", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysRevertBytecode,
    ]);
    await expect(nativeERC20.transfer(accounts[1].address, 1)).to.be.revertedWith("PRECOMPILE_CALL_FAILED");
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode,
    ]); // reset
  });

  it("transfer fail: from zero address", async () => {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ethers.constants.AddressZero],
    });
    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: [ethers.constants.AddressZero, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"],
    });
    zeroAddressNativeERC20 = nativeERC20.connect(await ethers.getSigner(ethers.constants.AddressZero));
    await expect(zeroAddressNativeERC20.transfer(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: transfer from the zero address"
    );
  });

  it("transfer fail: to zero address", async () => {
    await expect(nativeERC20.transfer(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: transfer to the zero address"
    );
  });

  it("transfer success", async () => {
    const transferAmount = Math.floor(Math.random() * totalSupply + 1);
    await expect(nativeERC20.transfer(accounts[1].address, transferAmount)).to.not.be.reverted;
    const receiverBalance = transferAmount;
    balance = BigNumber.from(ethers.utils.parseUnits(String(totalSupply))).sub(transferAmount);
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[0].address,
      ethers.utils.hexStripZeros(balance.toHexString()),
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[1].address,
      ethers.utils.hexStripZeros(BigNumber.from(receiverBalance).toHexString()),
    ]);
    expect(await nativeERC20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await nativeERC20.balanceOf(accounts[1].address)).to.equal(receiverBalance);
  });

  it("transferFrom fail: not approved", async () => {
    await expect(mockNativeERC20Transfer.transferFrom(nativeERC20.address, accounts[1].address, 1)).to.be.revertedWith(
      "ERC20: insufficient allowance"
    );
  });

  it("approve fail: from zero address", async () => {
    await expect(zeroAddressNativeERC20.approve(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: approve from the zero address"
    );
  });

  it("approve fail: to zero address", async () => {
    await expect(nativeERC20.approve(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: approve to the zero address"
    );
  });

  it("approve", async () => {
    const balance = await nativeERC20.balanceOf(accounts[0].address);
    await expect(nativeERC20.approve(mockNativeERC20Transfer.address, ethers.utils.parseUnits(balance.toString()))).to
      .not.be.reverted;
    expect(await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).to.equal(
      ethers.utils.parseUnits(balance.toString())
    );
  });

  it("transferFrom", async () => {
    const transferAmount = Math.floor(Math.random() * 1000000 + 1);
    await expect(mockNativeERC20Transfer.transferFrom(nativeERC20.address, accounts[1].address, transferAmount)).to.not
      .be.reverted;

    const receiverBalance = (await nativeERC20.balanceOf(accounts[1].address)).add(transferAmount);
    balance = BigNumber.from(await nativeERC20.balanceOf(accounts[0].address)).sub(transferAmount);
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[0].address,
      ethers.utils.hexStripZeros(balance.toHexString()),
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[1].address,
      ethers.utils.hexStripZeros(receiverBalance.toHexString()),
    ]);
    expect(await nativeERC20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await nativeERC20.balanceOf(accounts[1].address)).to.equal(receiverBalance);
  });

  it("increaseAllowance", async () => {
    const allowanceAmount = Math.floor(Math.random() * 1000000 + 1);
    const newAllowance = (await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).add(
      allowanceAmount
    );
    await expect(nativeERC20.increaseAllowance(mockNativeERC20Transfer.address, allowanceAmount)).to.not.be.reverted;
    expect(await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).to.equal(newAllowance);
  });

  it("decreaseAllowance fail: underflow", async () => {
    const allowanceAmount = (await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).add(1);
    const newAllowance = (await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).sub(
      allowanceAmount
    );
    await expect(nativeERC20.decreaseAllowance(mockNativeERC20Transfer.address, allowanceAmount)).to.be.revertedWith(
      "ERC20: decreased allowance below zero"
    );
  });

  it("decreaseAllowance", async () => {
    const allowanceAmount = Math.floor(Math.random() * 1000000 + 1);
    const newAllowance = (await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).sub(
      allowanceAmount
    );
    await expect(nativeERC20.decreaseAllowance(mockNativeERC20Transfer.address, allowanceAmount)).to.not.be.reverted;
    expect(await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).to.equal(newAllowance);
  });

  it("approve infinite allowance and transferFrom", async () => {
    await expect(nativeERC20.approve(mockNativeERC20Transfer.address, ethers.constants.MaxUint256)).to.not.be.reverted;
    expect(await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).to.equal(
      ethers.constants.MaxUint256
    );
    let balance = await nativeERC20.balanceOf(accounts[0].address);
    const transferAmount = Math.floor(Math.random() * 1000000 + 1);
    await expect(mockNativeERC20Transfer.transferFrom(nativeERC20.address, accounts[1].address, transferAmount)).to.not
      .be.reverted;
    const receiverBalance = ethers.utils.hexStripZeros(
      (await nativeERC20.balanceOf(accounts[1].address)).add(transferAmount).toHexString()
    );
    balance = BigNumber.from(ethers.utils.hexStripZeros(BigNumber.from(balance).sub(transferAmount).toHexString()));
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[0].address,
      ethers.utils.hexStripZeros(balance.toHexString()),
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      accounts[1].address,
      ethers.utils.hexStripZeros(BigNumber.from(receiverBalance).toHexString()),
    ]);
    expect(await nativeERC20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await nativeERC20.balanceOf(accounts[1].address)).to.equal(receiverBalance);
    expect(await nativeERC20.allowance(accounts[0].address, mockNativeERC20Transfer.address)).to.equal(
      ethers.constants.MaxUint256
    );
  });

  it("burn fail: pre-compile call failed", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysFalseBytecode,
    ]);
    await expect(predicateNativeERC20.burn(accounts[0].address, 1)).to.be.revertedWith("PRECOMPILE_CALL_FAILED");
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode,
    ]); // reset
  });

  it("burn fail: only predicate", async () => {
    await expect(nativeERC20.burn(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "NativeERC20: Only predicate or owner can call"
    );
  });

  it("burn fail: zero address", async () => {
    await expect(predicateNativeERC20.burn(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: burn from the zero address"
    );
  });

  it("burn success", async () => {
    const burnAmount = Math.floor(Math.random() * totalSupply + 1);
    totalSupply -= burnAmount;
    const expectedTotalSupply = (await nativeERC20.totalSupply()).sub(burnAmount);
    await expect(predicateNativeERC20.burn(accounts[0].address, burnAmount)).to.not.be.reverted;
    const balance = ethers.utils.hexStripZeros(
      BigNumber.from(await nativeERC20.balanceOf(accounts[0].address))
        .sub(burnAmount)
        .toHexString()
    );
    await hre.network.provider.send("hardhat_setBalance", [accounts[0].address, balance]);
    expect(await nativeERC20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await nativeERC20.totalSupply()).to.equal(expectedTotalSupply);
  });

  it("burn success from minter", async () => {
    const burnAmount = Math.floor(Math.random() * totalSupply + 1);
    totalSupply -= burnAmount;
    const expectedTotalSupply = (await nativeERC20.totalSupply()).sub(burnAmount);
    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: [accounts[1].address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"],
    });
    await expect(minterNativeERC20.burn(accounts[0].address, burnAmount)).to.not.be.reverted;
    const balance = ethers.utils.hexStripZeros(
      BigNumber.from(await nativeERC20.balanceOf(accounts[0].address))
        .sub(burnAmount)
        .toHexString()
    );
    await hre.network.provider.send("hardhat_setBalance", [accounts[0].address, balance]);
    expect(await nativeERC20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await nativeERC20.totalSupply()).to.equal(expectedTotalSupply);
  });
});
