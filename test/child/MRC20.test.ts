import { expect } from "chai";
import { BigNumber } from "ethers";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { MaticTransfer, MRC20 } from "../../typechain-types";
import { alwaysFalseBytecode, alwaysRevertBytecode, alwaysTrueBytecode } from "../constants";

describe("MRC20", () => {
  let mrc20: MRC20,
    systemMRC20: MRC20,
    stateReceiverMRC20: MRC20,
    zeroAddressMRC20: MRC20,
    maticTransfer: MaticTransfer,
    name: string,
    symbol: string,
    decimals: number,
    balance: string,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    accounts = await ethers.getSigners();
    const mrc20Factory = await ethers.getContractFactory("MRC20");
    mrc20 = (await mrc20Factory.deploy()) as MRC20;

    await mrc20.deployed();

    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      "0x0000000000000000000000000000000000001001",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      "0x0000000000000000000000000000000000000000",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });
    const systemSigner = await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    systemMRC20 = await mrc20.connect(systemSigner);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x0000000000000000000000000000000000001001"],
    });
    const stateReceiverSigner = await ethers.getSigner("0x0000000000000000000000000000000000001001");
    stateReceiverMRC20 = await mrc20.connect(stateReceiverSigner);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x0000000000000000000000000000000000000000"],
    });
    const zeroAddressSigner = await ethers.getSigner("0x0000000000000000000000000000000000000000");
    zeroAddressMRC20 = await mrc20.connect(zeroAddressSigner);

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode, // native transfer pre-compile
    ]);

    const maticTransferFactory = await ethers.getContractFactory("MaticTransfer");
    maticTransfer = (await maticTransferFactory.deploy()) as MaticTransfer;

    await maticTransfer.deployed();
  });

  it("fail initialization without system call", async () => {
    name = "MATIC Token";
    symbol = "MATIC";
    await expect(mrc20.initialize(accounts[1].address, name, symbol))
      .to.be.revertedWithCustomError(mrc20, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("validate initialization", async () => {
    await systemMRC20.initialize(accounts[1].address, name, symbol);
    expect(await mrc20.name()).to.equal("MATIC Token");
    expect(await mrc20.symbol()).to.equal("MATIC");
    expect(await mrc20.decimals()).to.equal(18);
    expect(await mrc20.totalSupply()).to.equal(0);
  });

  it("mint tokens fail: only state receiver", async () => {
    await expect(mrc20.onStateReceive(1, ethers.constants.AddressZero, ethers.constants.HashZero)).to.be.revertedWith(
      "ONLY_STATERECEIVER"
    );
  });

  it("mint tokens fail: invalid sender", async () => {
    await expect(
      stateReceiverMRC20.onStateReceive(1, ethers.constants.AddressZero, ethers.constants.HashZero)
    ).to.be.revertedWith("INVALID_SENDER");
  });

  it("mint tokens fail: zero address", async () => {
    const data = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [ethers.constants.AddressZero, 1]);
    await expect(stateReceiverMRC20.onStateReceive(1, accounts[1].address, data)).to.be.revertedWith(
      "ERC20: mint to the zero address"
    );
  });

  it("mint tokens fail: pre-compile call failed", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysFalseBytecode,
    ]);
    const data = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [accounts[0].address, 1]);
    await expect(stateReceiverMRC20.onStateReceive(1, accounts[1].address, data)).to.be.revertedWith(
      "PRECOMPILE_CALL_FAILED"
    );
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode,
    ]);
  });

  it("mint tokens", async () => {
    balance = ethers.utils.hexStripZeros(
      ethers.utils.parseUnits(String(Math.floor(Math.random() * 100000 + 10))).toHexString()
    );
    const address = accounts[0].address;
    const data = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [address, balance.toString()]);
    await expect(stateReceiverMRC20.onStateReceive(1, accounts[1].address, data)).to.not.be.reverted;
    await hre.network.provider.send("hardhat_setBalance", [address, balance]);
    expect(await mrc20.totalSupply()).to.equal(balance);
  });

  it("balanceOf", async () => {
    expect(await mrc20.balanceOf(accounts[0].address), balance);
  });

  it("transfer fail: pre-compile returns false", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysFalseBytecode,
    ]);
    await expect(mrc20.transfer(accounts[1].address, 1)).to.be.revertedWith("PRECOMPILE_CALL_FAILED");
  });

  it("transfer fail: pre-compile reverts", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysRevertBytecode,
    ]);
    await expect(mrc20.transfer(accounts[1].address, 1)).to.be.revertedWith("PRECOMPILE_CALL_FAILED");
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode,
    ]); // reset
  });

  it("transfer fail: from zero address", async () => {
    await expect(zeroAddressMRC20.transfer(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: transfer from the zero address"
    );
  });

  it("transfer fail: to zero address", async () => {
    await expect(mrc20.transfer(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: transfer to the zero address"
    );
  });

  it("transfer", async () => {
    let transferAmount = Math.floor(Math.random() * 10000 + 1);
    await expect(mrc20.transfer(accounts[1].address, transferAmount)).to.not.be.reverted;
    const receiverBalance = ethers.utils.hexStripZeros(
      (await mrc20.balanceOf(accounts[1].address)).add(transferAmount).toHexString()
    );
    balance = ethers.utils.hexStripZeros(BigNumber.from(balance).sub(transferAmount).toHexString());
    await hre.network.provider.send("hardhat_setBalance", [accounts[0].address, balance]);
    await hre.network.provider.send("hardhat_setBalance", [accounts[1].address, receiverBalance]);
    expect(await mrc20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await mrc20.balanceOf(accounts[1].address)).to.equal(receiverBalance);
  });

  it("transferFrom fail: not approved", async () => {
    await expect(maticTransfer.transferFrom(mrc20.address, accounts[1].address, 1)).to.be.revertedWith(
      "ERC20: insufficient allowance"
    );
  });

  it("approve fail: from zero address", async () => {
    await expect(zeroAddressMRC20.approve(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: approve from the zero address"
    );
  });

  it("approve fail: to zero address", async () => {
    await expect(mrc20.approve(ethers.constants.AddressZero, 1)).to.be.revertedWith(
      "ERC20: approve to the zero address"
    );
  });

  it("approve", async () => {
    await expect(mrc20.approve(maticTransfer.address, balance)).to.not.be.reverted;
    expect(await mrc20.allowance(accounts[0].address, maticTransfer.address)).to.equal(balance);
  });

  it("transferFrom", async () => {
    const transferAmount = Math.floor(Math.random() * 10000 + 1);
    await expect(maticTransfer.transferFrom(mrc20.address, accounts[1].address, transferAmount)).to.not.be.reverted;
    const receiverBalance = ethers.utils.hexStripZeros(
      (await mrc20.balanceOf(accounts[1].address)).add(transferAmount).toHexString()
    );
    balance = ethers.utils.hexStripZeros(BigNumber.from(balance).sub(transferAmount).toHexString());
    await hre.network.provider.send("hardhat_setBalance", [accounts[0].address, balance]);
    await hre.network.provider.send("hardhat_setBalance", [accounts[1].address, receiverBalance]);
    expect(await mrc20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await mrc20.balanceOf(accounts[1].address)).to.equal(receiverBalance);
  });

  it("increaseAllowance", async () => {
    const allowanceAmount = Math.floor(Math.random() * 10000 + 1);
    const newAllowance = (await mrc20.allowance(accounts[0].address, maticTransfer.address)).add(allowanceAmount);
    await expect(mrc20.increaseAllowance(maticTransfer.address, allowanceAmount)).to.not.be.reverted;
    expect(await mrc20.allowance(accounts[0].address, maticTransfer.address)).to.equal(newAllowance);
  });

  it("decreaseAllowance fail: underflow", async () => {
    const allowanceAmount = (await mrc20.allowance(accounts[0].address, maticTransfer.address)).add(1);
    const newAllowance = (await mrc20.allowance(accounts[0].address, maticTransfer.address)).sub(allowanceAmount);
    await expect(mrc20.decreaseAllowance(maticTransfer.address, allowanceAmount)).to.be.revertedWith(
      "ERC20: decreased allowance below zero"
    );
  });

  it("decreaseAllowance", async () => {
    const allowanceAmount = Math.floor(Math.random() * 10000 + 1);
    const newAllowance = (await mrc20.allowance(accounts[0].address, maticTransfer.address)).sub(allowanceAmount);
    await expect(mrc20.decreaseAllowance(maticTransfer.address, allowanceAmount)).to.not.be.reverted;
    expect(await mrc20.allowance(accounts[0].address, maticTransfer.address)).to.equal(newAllowance);
  });

  it("approve infinite allowance and transferFrom", async () => {
    await expect(mrc20.approve(maticTransfer.address, ethers.constants.MaxUint256)).to.not.be.reverted;
    expect(await mrc20.allowance(accounts[0].address, maticTransfer.address)).to.equal(ethers.constants.MaxUint256);
    const transferAmount = Math.floor(Math.random() * 10000 + 1);
    await expect(maticTransfer.transferFrom(mrc20.address, accounts[1].address, transferAmount)).to.not.be.reverted;
    const receiverBalance = ethers.utils.hexStripZeros(
      (await mrc20.balanceOf(accounts[1].address)).add(transferAmount).toHexString()
    );
    balance = ethers.utils.hexStripZeros(BigNumber.from(balance).sub(transferAmount).toHexString());
    await hre.network.provider.send("hardhat_setBalance", [accounts[0].address, balance]);
    await hre.network.provider.send("hardhat_setBalance", [accounts[1].address, receiverBalance]);
    expect(await mrc20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await mrc20.balanceOf(accounts[1].address)).to.equal(receiverBalance);
    expect(await mrc20.allowance(accounts[0].address, maticTransfer.address)).to.equal(ethers.constants.MaxUint256);
  });

  it("withdraw fail: pre-compile call failed", async () => {
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysFalseBytecode,
    ]);
    await expect(mrc20.withdraw(1)).to.be.revertedWith("PRECOMPILE_CALL_FAILED");
    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode,
    ]); // reset
  });

  it("withdraw fail: zero address", async () => {
    await expect(zeroAddressMRC20.withdraw(1)).to.be.revertedWith("ERC20: burn from the zero address");
  });

  it("withdraw", async () => {
    const oldSupply = await mrc20.totalSupply();
    const burnAmount = Math.floor(Math.random() * 10000 + 1);
    await expect(mrc20.withdraw(burnAmount)).to.not.be.reverted;
    balance = ethers.utils.hexStripZeros(BigNumber.from(balance).sub(burnAmount).toHexString());
    await hre.network.provider.send("hardhat_setBalance", [accounts[0].address, balance]);
    expect(await mrc20.balanceOf(accounts[0].address)).to.equal(balance);
    expect(await mrc20.totalSupply()).to.equal(oldSupply.sub(burnAmount));
  });
});
