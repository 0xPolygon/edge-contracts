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
    depositedTokenIds: number[] = [],
    batchDepositedTokenIds: number[] = [],
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
  });

  it("fail initialization", async () => {
    await expect(childERC721.initialize(ethers.constants.AddressZero, "", "")).to.be.revertedWith(
      "ChildERC721: Bad initialization"
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
    await expect(childERC721.burn(ethers.constants.AddressZero, 0)).to.be.revertedWith(
      "ChildERC721: Only predicate can call"
    );
  });

  it("mint tokens success", async () => {
    const randomTokenId = Math.floor(Math.random() * 1000000 + 1);
    depositedTokenIds.push(randomTokenId);
    const mintTx = await predicateChildERC721.mint(accounts[0].address, randomTokenId);
    const mintReceipt = await mintTx.wait();

    const transferEvent = mintReceipt?.events?.find((log) => log.event === "Transfer");

    expect(transferEvent?.args?.from).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.to).to.equal(accounts[0].address);
    expect(transferEvent?.args?.tokenId).to.equal(randomTokenId);
  });

  it("batch mint tokens fail: only predicate", async () => {
    await expect(childERC721.mintBatch([], [])).to.be.revertedWith("ChildERC721: Only predicate can call");
  });

  it("batch mint tokens fail: length mismatch", async () => {
    await expect(predicateChildERC721.mintBatch([], [0])).to.be.revertedWith("ChildERC721: Array len mismatch");
  });

  it("batch mint tokens success", async () => {
    const batchSize = Math.floor(Math.random() * 10 + 2);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      const randomTokenId = Math.floor(Math.random() * 1000000 + 1);
      batchDepositedTokenIds.push(randomTokenId);
      receiverArr.push(accounts[1].address);
    }
    const mintTx = await predicateChildERC721.mintBatch(receiverArr, batchDepositedTokenIds);
    const mintReceipt = await mintTx.wait();

    const transferEvents = mintReceipt?.events?.filter((log: any) => log.event === "Transfer");
    for (let i = 0; i < transferEvents!.length; i++) {
      expect(transferEvents![i]?.args?.from).to.equal(ethers.constants.AddressZero);
      expect(transferEvents![i]?.args?.to).to.equal(accounts[1].address);
      expect(transferEvents![i]?.args?.tokenId).to.equal(batchDepositedTokenIds[i]);
    }
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
      depositedTokenIds[0],
    ]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC721.interface.encodeFunctionData("transferFrom", [
        accounts[0].address,
        accounts[1].address,
        depositedTokenIds[0],
      ]),
    };

    const signature = await (await ethers.getSigner(accounts[1].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    await expect(childERC721.executeMetaTransaction(accounts[0].address, functionData, r, s, v)).to.be.revertedWith(
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
      depositedTokenIds[0],
    ]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC721.interface.encodeFunctionData("transferFrom", [
        accounts[0].address,
        accounts[1].address,
        depositedTokenIds[0],
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
    expect(transferEvent?.args?.to).to.equal(accounts[1].address);
    expect(transferEvent?.args?.tokenId).to.equal(depositedTokenIds[0]);
  });

  it("burn tokens fail: only token owner", async () => {
    await expect(predicateChildERC721.burn(accounts[0].address, depositedTokenIds[0])).to.be.revertedWith(
      "ChildERC721: Only owner can burn"
    );
  });

  it("burn tokens success", async () => {
    const burnTx = await predicateChildERC721.burn(accounts[1].address, depositedTokenIds[0]);
    const burnReceipt = await burnTx.wait();

    const transferEvent = burnReceipt?.events?.find((log: any) => log.event === "Transfer");
    expect(transferEvent?.args?.from).to.equal(accounts[1].address);
    expect(transferEvent?.args?.to).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.tokenId).to.equal(depositedTokenIds[0]);
  });

  it("batch burn tokens fail: only predicate", async () => {
    await expect(childERC721.burnBatch(ethers.constants.AddressZero, [])).to.be.revertedWith(
      "ChildERC721: Only predicate can call"
    );
  });

  it("batch burn tokens fail: only token owner", async () => {
    await expect(
      predicateChildERC721.burnBatch(ethers.constants.AddressZero, batchDepositedTokenIds)
    ).to.be.revertedWith("ChildERC721: Only owner can burn");
  });

  it("batch burn tokens success", async () => {
    const batchSize = Math.floor(Math.random() * batchDepositedTokenIds.length + 2);
    const mintTx = await predicateChildERC721.burnBatch(
      accounts[1].address,
      batchDepositedTokenIds.slice(0, batchSize)
    );
    const mintReceipt = await mintTx.wait();

    const transferEvents = mintReceipt?.events?.filter((log: any) => log.event === "Transfer");
    for (let i = 0; i < transferEvents!.length; i++) {
      expect(transferEvents![i]?.args?.from).to.equal(accounts[1].address);
      expect(transferEvents![i]?.args?.to).to.equal(ethers.constants.AddressZero);
      expect(transferEvents![i]?.args?.tokenId).to.equal(batchDepositedTokenIds[i]);
    }
  });
});
