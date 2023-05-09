import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildERC1155,
  ChildERC1155__factory,
  ChildERC1155Predicate,
  ChildERC1155Predicate__factory,
} from "../../typechain-types";
import { setBalance, impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("ChildERC1155", () => {
  let childERC1155: ChildERC1155,
    predicateChildERC1155: ChildERC1155,
    childERC1155Predicate: ChildERC1155Predicate,
    rootToken: string,
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const ChildERC1155: ChildERC1155__factory = await ethers.getContractFactory("ChildERC1155");
    childERC1155 = await ChildERC1155.deploy();

    await childERC1155.deployed();

    const ChildERC1155Predicate: ChildERC1155Predicate__factory = await ethers.getContractFactory(
      "ChildERC1155Predicate"
    );
    childERC1155Predicate = await ChildERC1155Predicate.deploy();

    await childERC1155Predicate.deployed();

    impersonateAccount(childERC1155Predicate.address);
    setBalance(childERC1155Predicate.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    rootToken = ethers.Wallet.createRandom().address;
  });

  it("fail initialization", async () => {
    await expect(childERC1155.initialize(ethers.constants.AddressZero, "")).to.be.revertedWith(
      "ChildERC1155: BAD_INITIALIZATION"
    );
  });

  it("initialize and validate initialization", async () => {
    expect(await childERC1155.rootToken()).to.equal(ethers.constants.AddressZero);
    expect(await childERC1155.predicate()).to.equal(ethers.constants.AddressZero);

    predicateChildERC1155 = childERC1155.connect(await ethers.getSigner(childERC1155Predicate.address));
    await predicateChildERC1155.initialize(rootToken, "TEST");

    expect(await childERC1155.rootToken()).to.equal(rootToken);
    expect(await childERC1155.predicate()).to.equal(childERC1155Predicate.address);
  });

  it("fail reinitialization", async () => {
    await expect(childERC1155.initialize(ethers.constants.AddressZero, "")).to.be.revertedWith(
      "Initializable: contract is already initialized"
    );
  });

  it("mint tokens fail: only predicate", async () => {
    await expect(childERC1155.mint(ethers.constants.AddressZero, 0, 1)).to.be.revertedWith(
      "ChildERC1155: Only predicate can call"
    );
  });

  it("burn tokens fail: only predicate", async () => {
    await expect(childERC1155.burn(ethers.constants.AddressZero, 0, 1)).to.be.revertedWith(
      "ChildERC1155: Only predicate can call"
    );
  });

  it("mint tokens success", async () => {
    const mintTx = await predicateChildERC1155.mint(accounts[0].address, 0, 1);
    const mintReceipt = await mintTx.wait();

    const transferEvent = mintReceipt?.events?.find((log) => log.event === "TransferSingle");

    expect(transferEvent?.args?.from).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.to).to.equal(accounts[0].address);
    expect(transferEvent?.args?.id).to.equal(0);
    expect(transferEvent?.args?.value).to.equal(1);
  });

  it("execute meta-tx: fail", async () => {
    const domain = {
      name: "TEST",
      version: "1",
      chainId: network.config.chainId,
      verifyingContract: childERC1155.address,
    };

    const types = {
      MetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "functionSignature", type: "bytes" },
      ],
    };

    const functionData = childERC1155.interface.encodeFunctionData("safeTransferFrom", [
      accounts[0].address,
      accounts[1].address,
      0,
      1,
      [],
    ]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC1155.interface.encodeFunctionData("safeTransferFrom", [
        accounts[0].address,
        accounts[1].address,
        0,
        1,
        [],
      ]),
    };

    const signature = await (await ethers.getSigner(accounts[0].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    await expect(childERC1155.executeMetaTransaction(accounts[1].address, functionData, r, s, v)).to.be.revertedWith(
      "Signer and signature do not match"
    );
  });

  it("execute meta-tx: success", async () => {
    const domain = {
      name: `ChildERC1155-${(await childERC1155.rootToken()).toLowerCase()}`,
      version: "1",
      chainId: network.config.chainId,
      verifyingContract: childERC1155.address,
    };

    const types = {
      MetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "functionSignature", type: "bytes" },
      ],
    };

    const functionData = childERC1155.interface.encodeFunctionData("safeTransferFrom", [
      accounts[0].address,
      accounts[1].address,
      0,
      1,
      [],
    ]);
    const value = {
      nonce: 0,
      from: accounts[0].address,
      functionSignature: childERC1155.interface.encodeFunctionData("safeTransferFrom", [
        accounts[0].address,
        accounts[1].address,
        0,
        1,
        [],
      ]),
    };

    const signature = await (await ethers.getSigner(accounts[0].address))._signTypedData(domain, types, value);
    const r = signature.slice(0, 66);
    const s = "0x".concat(signature.slice(66, 130));
    let v: any = "0x".concat(signature.slice(130, 132));
    v = ethers.BigNumber.from(v).toNumber();
    const transferTx = await childERC1155.executeMetaTransaction(accounts[0].address, functionData, r, s, v);
    const transferReceipt = await transferTx.wait();

    const transferEvent = transferReceipt?.events?.find((log) => log.event === "TransferSingle");
    expect(transferEvent?.args?.from).to.equal(accounts[0].address);
    expect(transferEvent?.args?.to).to.equal(accounts[1].address);
    expect(transferEvent?.args?.value).to.equal(1);
  });

  it("burn tokens success", async () => {
    const burnTx = await predicateChildERC1155.burn(accounts[1].address, 0, 1);
    const burnReceipt = await burnTx.wait();

    const transferEvent = burnReceipt?.events?.find((log: any) => log.event === "TransferSingle");
    expect(transferEvent?.args?.from).to.equal(accounts[1].address);
    expect(transferEvent?.args?.to).to.equal(ethers.constants.AddressZero);
    expect(transferEvent?.args?.value).to.equal(1);
  });

  it("batch mint tokens success", async () => {
    const mintTx = await predicateChildERC1155.mintBatch(
      [accounts[0].address, accounts[0].address, accounts[1].address],
      [0, 1, 2],
      [1, 2, 3]
    );
    await expect(mintTx)
      .to.emit(predicateChildERC1155, "TransferSingle")
      .withArgs("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", ethers.constants.AddressZero, accounts[0].address, 0, 1);
    await expect(mintTx)
      .to.emit(predicateChildERC1155, "TransferSingle")
      .withArgs("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", ethers.constants.AddressZero, accounts[0].address, 1, 2);
    await expect(mintTx)
      .to.emit(predicateChildERC1155, "TransferSingle")
      .withArgs("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", ethers.constants.AddressZero, accounts[1].address, 2, 3);
  });
  it("batch burn tokens success", async () => {
    const burnTx = await predicateChildERC1155.burnBatch(accounts[0].address, [0, 1], [1, 2]);
    await expect(burnTx)
      .to.emit(predicateChildERC1155, "TransferBatch")
      .withArgs(
        "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
        accounts[0].address,
        ethers.constants.AddressZero,
        [0, 1],
        [1, 2]
      );
  });
});
