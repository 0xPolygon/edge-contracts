import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildERC20,
  ChildERC20__factory,
  ChildERC20Predicate,
  ChildERC20Predicate__factory,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("ChildERC20", () => {
  let childERC20: ChildERC20,
    predicateChildERC20: ChildERC20,
    childERC20Predicate: ChildERC20Predicate,
    rootToken: string,
    totalSupply: number,
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const ChildERC20: ChildERC20__factory = await ethers.getContractFactory("ChildERC20");
    childERC20 = await ChildERC20.deploy();

    await childERC20.deployed();

    const ChildERC20Predicate: ChildERC20Predicate__factory = await ethers.getContractFactory("ChildERC20Predicate");
    childERC20Predicate = await ChildERC20Predicate.deploy();

    await childERC20Predicate.deployed();

    impersonateAccount(childERC20Predicate.address);
    setBalance(childERC20Predicate.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    rootToken = ethers.Wallet.createRandom().address;

    totalSupply = 0;
  });

  it("fail initialization", async () => {
    await expect(childERC20.initialize(ethers.constants.AddressZero, "", "", 0)).to.be.revertedWith(
      "ChildERC20: BAD_INITIALIZATION"
    );
  });

  it("initialize and validate initialization", async () => {
    expect(await childERC20.rootToken()).to.equal(ethers.constants.AddressZero);
    expect(await childERC20.predicate()).to.equal(ethers.constants.AddressZero);
    expect(await childERC20.name()).to.equal("");
    expect(await childERC20.symbol()).to.equal("");
    expect(await childERC20.decimals()).to.equal(0);

    predicateChildERC20 = childERC20.connect(await ethers.getSigner(childERC20Predicate.address));
    await predicateChildERC20.initialize(rootToken, "TEST", "TEST", 18);

    expect(await childERC20.rootToken()).to.equal(rootToken);
    expect(await childERC20.predicate()).to.equal(childERC20Predicate.address);
    expect(await childERC20.name()).to.equal("TEST");
    expect(await childERC20.symbol()).to.equal("TEST");
    expect(await childERC20.decimals()).to.equal(18);
  });

  it("fail reinitialization", async () => {
    await expect(childERC20.initialize(ethers.constants.AddressZero, "", "", 0)).to.be.revertedWith(
      "Initializable: contract is already initialized"
    );
  });

  it("mint tokens fail: only predicate", async () => {
    await expect(childERC20.mint(ethers.constants.AddressZero, 0)).to.be.revertedWith(
      "ChildERC20: Only predicate can call"
    );
  });

  it("burn tokens fail: only predicate", async () => {
    await expect(childERC20.burn(ethers.constants.AddressZero, 0)).to.be.revertedWith(
      "ChildERC20: Only predicate can call"
    );
  });

  it("mint tokens success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    const mintTx = await predicateChildERC20.mint(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    const mintReceipt = await mintTx.wait();

    const transferEvent = mintReceipt?.events?.find((log) => log.event === "Transfer");

    expect(transferEvent?.args?.from).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.to).to.equal(accounts[0].address);
    expect(transferEvent?.args?.value).to.equal(ethers.utils.parseUnits(String(randomAmount)));
    expect(await childERC20.totalSupply()).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("execute meta-tx: fail", async () => {
    const domain = {
      name: "TEST",
      version: "1",
      chainId: network.config.chainId,
      verifyingContract: childERC20.address,
    };

    const types = {
      MetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "functionSignature", type: "bytes" },
      ],
    };

    const functionData = childERC20.interface.encodeFunctionData("transfer", [accounts[0].address, 1]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC20.interface.encodeFunctionData("transfer", [accounts[0].address, 1]),
    };

    const signature = await (await ethers.getSigner(accounts[0].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    await expect(childERC20.executeMetaTransaction(accounts[1].address, functionData, r, s, v)).to.be.revertedWith(
      "Signer and signature do not match"
    );
  });

  it("execute meta-tx: success", async () => {
    const domain = {
      name: "TEST",
      version: "1",
      chainId: network.config.chainId,
      verifyingContract: childERC20.address,
    };

    const types = {
      MetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "functionSignature", type: "bytes" },
      ],
    };

    const functionData = childERC20.interface.encodeFunctionData("transfer", [accounts[0].address, 1]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC20.interface.encodeFunctionData("transfer", [accounts[0].address, 1]),
    };

    const signature = await (await ethers.getSigner(accounts[0].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    const transferTx = await childERC20.executeMetaTransaction(accounts[0].address, functionData, r, s, v);
    const transferReceipt = await transferTx.wait();

    const transferEvent = transferReceipt?.events?.find((log) => log.event === "Transfer");
    expect(transferEvent?.args?.from).to.equal(accounts[0].address);
    expect(transferEvent?.args?.to).to.equal(accounts[0].address);
    expect(transferEvent?.args?.value).to.equal(1);
  });

  it("burn tokens success", async () => {
    const randomAmount = Math.floor(Math.random() * totalSupply + 1);
    totalSupply -= randomAmount;
    const burnTx = await predicateChildERC20.burn(accounts[0].address, ethers.utils.parseUnits(String(randomAmount)));
    const burnReceipt = await burnTx.wait();

    const transferEvent = burnReceipt?.events?.find((log: any) => log.event === "Transfer");
    expect(transferEvent?.args?.from).to.equal(accounts[0].address);
    expect(transferEvent?.args?.to).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.value).to.equal(ethers.utils.parseUnits(String(randomAmount)));
    expect(await childERC20.totalSupply()).to.equal(ethers.utils.parseUnits(String(totalSupply)));
  });
});
