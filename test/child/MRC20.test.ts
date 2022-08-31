import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { FakeContract, smock } from "@defi-wonderland/smock";
import { MRC20 } from "../../typechain";
import { alwaysTrueBytecode, alwaysFalseBytecode, alwaysRevertBytecode } from "../constants";
import { customError } from "../util";

describe("MRC20", () => {
  let mrc20: MRC20,
    systemMRC20: MRC20,
    stateReceiverMRC20: MRC20,
    name: string,
    symbol: string,
    decimals: number,
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    accounts = await ethers.getSigners();
    const mrc20Factory = await ethers.getContractFactory("MRC20");
    mrc20 = await mrc20Factory.deploy();

    await mrc20.deployed();

    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      "0x0000000000000000000000000000000000001001",
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

    await hre.network.provider.send("hardhat_setCode", [
      "0x0000000000000000000000000000000000002020",
      alwaysTrueBytecode, // native transfer pre-compile
    ]);
  });

  it("fail initialization without system call", async () => {
    name = "MATIC Token";
    symbol = "MATIC";
    await expect(mrc20.initialize(accounts[1].address, name, symbol)).to.be.revertedWith(
      customError("Unauthorized", "SYSTEMCALL")
    );
  });

  it("validate initialization", async () => {
    await systemMRC20.initialize(accounts[1].address, name, symbol);
    expect(await mrc20.name()).to.equal("MATIC Token");
    expect(await mrc20.symbol()).to.equal("MATIC");
    expect(await mrc20.decimals()).to.equal(18);
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

  it("mint tokens", async () => {
    const amount = ethers.utils.parseUnits("1000");
    const address = accounts[0].address;
    const data = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [address, amount]);
    await stateReceiverMRC20.onStateReceive(1, accounts[1].address, data);
    await hre.network.provider.send("hardhat_setBalance", [address, amount.toHexString()]);
  });
});
