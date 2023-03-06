import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildERC721,
  ChildERC721__factory,
  ChildERC721Predicate,
  ChildERC721Predicate__factory,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("ChildERC721", () => {
  let childERC721: ChildERC721,
    predicateChildERC721: ChildERC721,
    childERC721Predicate: ChildERC721Predicate,
    rootToken: string,
    totalSupply: number,
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const ChildERC721: ChildERC721__factory = await ethers.getContractFactory("ChildERC721");
    childERC721 = await ChildERC721.deploy();

    await childERC721.deployed();

    const ChildERC721Predicate: ChildERC721Predicate__factory = await ethers.getContractFactory("ChildERC721Predicate");
    childERC721Predicate = await ChildERC721Predicate.deploy();

    await childERC721Predicate.deployed();

    impersonateAccount(childERC721Predicate.address);
    setBalance(childERC721Predicate.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    rootToken = ethers.Wallet.createRandom().address;

    totalSupply = 0;
  });

  it("fail initialization", async () => {
    await expect(childERC721.initialize(ethers.constants.AddressZero, "", "")).to.be.revertedWith(
      "ChildERC721: BAD_INITIALIZATION"
    );
  });

  it("initialize and validate initialization", async () => {
    expect(await childERC721.rootToken()).to.equal(ethers.constants.AddressZero);
    expect(await childERC721.predicate()).to.equal(ethers.constants.AddressZero);
    expect(await childERC721.name()).to.equal("");
    expect(await childERC721.symbol()).to.equal("");

    predicateChildERC721 = childERC721.connect(await ethers.getSigner(childERC721Predicate.address));
    await predicateChildERC721.initialize(rootToken, "TEST", "TEST");

    expect(await childERC721.rootToken()).to.equal(rootToken);
    expect(await childERC721.predicate()).to.equal(childERC721Predicate.address);
    expect(await childERC721.name()).to.equal("TEST");
    expect(await childERC721.symbol()).to.equal("TEST");
  });

  it("fail reinitialization", async () => {
    await expect(childERC721.initialize(ethers.constants.AddressZero, "", "")).to.be.revertedWith(
      "Initializable: contract is already initialized"
    );
  });

  it("mint tokens fail: only predicate", async () => {
    await expect(childERC721.mint(ethers.constants.AddressZero, 0)).to.be.revertedWith(
      "ChildERC721: Only predicate can call"
    );
  });

  it("burn tokens fail: only predicate", async () => {
    await expect(childERC721.burn(0)).to.be.revertedWith("ChildERC721: Only predicate can call");
  });

  it("mint tokens success", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    totalSupply += randomAmount;
    const mintTx = await predicateChildERC721.mint(accounts[0].address, 0);
    const mintReceipt = await mintTx.wait();

    const transferEvent = mintReceipt?.events?.find((log) => log.event === "Transfer");

    expect(transferEvent?.args?.from).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.to).to.equal(accounts[0].address);
    expect(transferEvent?.args?.value).to.equal(0);
  });

  it("execute meta-tx: fail", async () => {
    const domain = {
      name: "TEST",
      version: "1",
      chainId: network.config.chainId,
      verifyingContract: childERC721.address,
    };

    const types = {
      MetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "functionSignature", type: "bytes" },
      ],
    };

    const functionData = childERC721.interface.encodeFunctionData("transferFrom", [
      accounts[0].address,
      accounts[1].address,
      1,
    ]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC721.interface.encodeFunctionData("transferFrom", [
        accounts[0].address,
        accounts[1].address,
        1,
      ]),
    };

    const signature = await (await ethers.getSigner(accounts[0].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    await expect(childERC721.executeMetaTransaction(accounts[1].address, functionData, r, s, v)).to.be.revertedWith(
      "Signer and signature do not match"
    );
  });

  it("execute meta-tx: success", async () => {
    const domain = {
      name: "TEST",
      version: "1",
      chainId: network.config.chainId,
      verifyingContract: childERC721.address,
    };

    const types = {
      MetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "functionSignature", type: "bytes" },
      ],
    };

    const functionData = childERC721.interface.encodeFunctionData("transferFrom", [
      accounts[0].address,
      accounts[1].address,
      1,
    ]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC721.interface.encodeFunctionData("transferFrom", [
        accounts[0].address,
        accounts[1].address,
        1,
      ]),
    };

    const signature = await (await ethers.getSigner(accounts[0].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    const transferTx = await childERC721.executeMetaTransaction(accounts[0].address, functionData, r, s, v);
    const transferReceipt = await transferTx.wait();

    const transferEvent = transferReceipt?.events?.find((log) => log.event === "Transfer");
    expect(transferEvent?.args?.from).to.equal(accounts[0].address);
    expect(transferEvent?.args?.to).to.equal(accounts[0].address);
    expect(transferEvent?.args?.value).to.equal(1);
  });

  it("burn tokens success", async () => {
    const randomAmount = Math.floor(Math.random() * totalSupply + 1);
    totalSupply -= randomAmount;
    const burnTx = await predicateChildERC721.burn(ethers.utils.parseUnits(String(randomAmount)));
    const burnReceipt = await burnTx.wait();

    const transferEvent = burnReceipt?.events?.find((log: any) => log.event === "Transfer");
    expect(transferEvent?.args?.from).to.equal(accounts[0].address);
    expect(transferEvent?.args?.to).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.value).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("batch mint tokens success");
});
