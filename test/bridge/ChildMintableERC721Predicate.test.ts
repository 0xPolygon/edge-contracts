import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildMintableERC721Predicate,
  ChildMintableERC721Predicate__factory,
  StateSender,
  StateSender__factory,
  ExitHelper,
  ExitHelper__factory,
  ChildERC721,
  ChildERC721__factory,
} from "../../typechain-types";
import {
  setCode,
  setBalance,
  impersonateAccount,
  stopImpersonatingAccount,
} from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { smock } from "@defi-wonderland/smock";

describe("ChildMintableERC721Predicate", () => {
  let childMintableERC721Predicate: ChildMintableERC721Predicate,
    exitHelperChildMintableERC721Predicate: ChildMintableERC721Predicate,
    stateSender: StateSender,
    exitHelper: ExitHelper,
    rootERC721Predicate: string,
    childERC721: ChildERC721,
    rootToken: string,
    childTokenAddr: string,
    childToken: ChildERC721,
    depositedTokenIds: number[] = [],
    batchDepositedTokenIds: number[] = [],
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const StateSender: StateSender__factory = await ethers.getContractFactory("StateSender");
    stateSender = await StateSender.deploy();

    await stateSender.deployed();

    const ExitHelper: ExitHelper__factory = await ethers.getContractFactory("ExitHelper");
    exitHelper = await ExitHelper.deploy();

    await exitHelper.deployed();

    rootERC721Predicate = ethers.Wallet.createRandom().address;

    const ChildERC721: ChildERC721__factory = await ethers.getContractFactory("ChildERC721");
    childERC721 = await ChildERC721.deploy();

    await childERC721.deployed();

    const ChildMintableERC721Predicate: ChildMintableERC721Predicate__factory = await ethers.getContractFactory(
      "ChildMintableERC721Predicate"
    );
    childMintableERC721Predicate = await ChildMintableERC721Predicate.deploy();

    await childMintableERC721Predicate.deployed();

    impersonateAccount(exitHelper.address);
    setBalance(exitHelper.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    exitHelperChildMintableERC721Predicate = childMintableERC721Predicate.connect(
      await ethers.getSigner(exitHelper.address)
    );
  });

  it("fail bad initialization", async () => {
    await expect(
      childMintableERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("ChildMintableERC721Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await childMintableERC721Predicate.initialize(
      stateSender.address,
      exitHelper.address,
      rootERC721Predicate,
      childERC721.address
    );
    expect(await childMintableERC721Predicate.stateSender()).to.equal(stateSender.address);
    expect(await childMintableERC721Predicate.exitHelper()).to.equal(exitHelper.address);
    expect(await childMintableERC721Predicate.rootERC721Predicate()).to.equal(rootERC721Predicate);
    expect(await childMintableERC721Predicate.childTokenTemplate()).to.equal(childERC721.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      childMintableERC721Predicate.initialize(
        stateSender.address,
        exitHelper.address,
        rootERC721Predicate,
        childERC721.address
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("map token success", async () => {
    rootToken = ethers.Wallet.createRandom().address;
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    childTokenAddr = await clonesContract.predictDeterministicAddress(
      childERC721.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken]),
      childMintableERC721Predicate.address
    );
    childToken = childERC721.attach(childTokenAddr);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST", "TEST", 18]
    );
    const mapTx = await exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log) => log.event === "MintableTokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await childToken.predicate()).to.equal(childMintableERC721Predicate.address);
    expect(await childToken.rootToken()).to.equal(rootToken);
    expect(await childToken.name()).to.equal("TEST");
    expect(await childToken.symbol()).to.equal("TEST");
  });

  it("map token fail: invalid root token", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [
        ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]),
        "0x0000000000000000000000000000000000000000",
        "TEST",
        "TEST",
        18,
      ]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("map token fail: already mapped", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST", "TEST", 18]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("deposit fail: unmapped token", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        ethers.Wallet.createRandom().address,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: UNMAPPED_TOKEN");
  });

  it("deposit tokens from root chain with same address", async () => {
    const randomTokenId = Math.floor(Math.random() * 1000000 + 1);
    depositedTokenIds.push(randomTokenId);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[0].address,
        randomTokenId,
      ]
    );
    const depositTx = await exitHelperChildMintableERC721Predicate.onL2StateReceive(
      0,
      rootERC721Predicate,
      stateSyncData
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "MintableERC721Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(randomTokenId);
  });

  it("deposit tokens from root chain with different address", async () => {
    const randomTokenId = Math.floor(Math.random() * 1000000 + 1);
    depositedTokenIds.push(randomTokenId);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[1].address,
        randomTokenId,
      ]
    );
    const depositTx = await exitHelperChildMintableERC721Predicate.onL2StateReceive(
      0,
      rootERC721Predicate,
      stateSyncData
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "MintableERC721Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.tokenId).to.equal(randomTokenId);
  });

  it("deposit batch tokens from root chain", async () => {
    const batchSize = Math.floor(Math.random() * 10 + 1);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      const randomTokenId = Math.floor(Math.random() * 1000000 + 1);
      batchDepositedTokenIds.push(randomTokenId);
      receiverArr.push(accounts[2].address);
    }
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT_BATCH"]),
        rootToken,
        accounts[0].address,
        receiverArr,
        batchDepositedTokenIds,
      ]
    );
    const depositTx = await exitHelperChildMintableERC721Predicate.onL2StateReceive(
      0,
      rootERC721Predicate,
      stateSyncData
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "MintableERC721DepositBatch");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(batchDepositedTokenIds);
  });

  it("withdraw tokens from child chain with same address", async () => {
    const depositTx = await childMintableERC721Predicate.withdraw(childTokenAddr, depositedTokenIds[0]);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "MintableERC721Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(depositedTokenIds[0]);
  });

  it("withdraw tokens from child chain with different address", async () => {
    const depositTx = await childMintableERC721Predicate
      .connect(accounts[1])
      .withdrawTo(childTokenAddr, accounts[0].address, depositedTokenIds[1]);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "MintableERC721Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[1].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(depositedTokenIds[1]);
  });

  it("withdraw batch tokens fail: not contract", async () => {
    await expect(
      childMintableERC721Predicate.withdrawBatch(
        ethers.Wallet.createRandom().address,
        [ethers.constants.AddressZero],
        [0]
      )
    ).to.be.revertedWith("ChildMintableERC721Predicate: NOT_CONTRACT");
  });

  it("withdraw batch tokens from child chain", async () => {
    const batchSize = Math.floor(Math.random() * (await childToken.balanceOf(accounts[2].address)).toNumber() + 1);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      receiverArr.push(ethers.Wallet.createRandom().address);
    }
    const depositTx = await exitHelperChildMintableERC721Predicate
      .connect(accounts[2])
      .withdrawBatch(childTokenAddr, receiverArr, batchDepositedTokenIds.slice(0, batchSize));
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "MintableERC721WithdrawBatch");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[2].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(batchDepositedTokenIds.slice(0, batchSize));
  });

  it("fail deposit tokens: only exit helper", async () => {
    const tempChildMintableERC721Predicate = childMintableERC721Predicate.connect(accounts[19]);
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
      tempChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: ONLY_EXIT_HELPER");
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
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, ethers.Wallet.createRandom().address, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: ONLY_ROOT_PREDICATE");
  });

  it("fail deposit tokens: invalid signature", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.randomBytes(32),
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        accounts[0].address,
        accounts[0].address,
        1,
      ]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: INVALID_SIGNATURE");
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
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: not a contract", async () => {
    await expect(childMintableERC721Predicate.withdraw(ethers.Wallet.createRandom().address, 1)).to.be.revertedWith(
      "ChildMintableERC721Predicate: NOT_CONTRACT"
    );
  });

  it("fail deposit tokens of unknown child token: wrong deposit token", async () => {
    childMintableERC721Predicate.connect(await ethers.getSigner(exitHelper.address));
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "address", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        ethers.constants.AddressZero,
        childTokenAddr,
        accounts[0].address,
        accounts[0].address,
        0,
      ]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: UNMAPPED_TOKEN");
  });

  it("fail deposit tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC721")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST");
    let stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]), rootToken, accounts[0].address, accounts[0].address, 0]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: UNMAPPED_TOKEN");
    stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT_BATCH"]),
        rootToken,
        accounts[0].address,
        [accounts[0].address],
        [0],
      ]
    );
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC721")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST");
    await expect(exitHelperChildMintableERC721Predicate.withdraw(childToken.address, 0)).to.be.revertedWith(
      "ChildMintableERC721Predicate: UNMAPPED_TOKEN"
    );
    await expect(
      childMintableERC721Predicate.withdrawBatch(childToken.address, [ethers.constants.AddressZero], [0])
    ).to.be.revertedWith("ChildMintableERC721Predicate: UNMAPPED_TOKEN");
  });

  // since we fake ChildERC721 here, keep this function last:
  it("fail deposit tokens: mint failed", async () => {
    let stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256"],
      [ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]), rootToken, accounts[0].address, accounts[0].address, 1]
    );
    const fakeChildERC721 = await smock.fake<ChildERC721>("ChildERC721", {
      address: childTokenAddr,
    });
    fakeChildERC721.supportsInterface.returns(true);
    fakeChildERC721.rootToken.returns(rootToken);
    fakeChildERC721.predicate.returns(childMintableERC721Predicate.address);
    fakeChildERC721.mint.returns(false);
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: MINT_FAILED");
    stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT_BATCH"]),
        rootToken,
        accounts[0].address,
        [accounts[0].address],
        [1],
      ]
    );
    fakeChildERC721.mintBatch.returns(false);
    await expect(
      exitHelperChildMintableERC721Predicate.onL2StateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildMintableERC721Predicate: MINT_FAILED");
    fakeChildERC721.mint.returns();
  });

  it("fail withdraw tokens: burn failed", async () => {
    const fakeChildERC721 = await smock.fake<ChildERC721>("ChildERC721", {
      address: childTokenAddr,
    });
    fakeChildERC721.supportsInterface.returns(true);
    fakeChildERC721.rootToken.returns(rootToken);
    fakeChildERC721.predicate.returns(childMintableERC721Predicate.address);
    fakeChildERC721.burn.returns(false);
    await expect(exitHelperChildMintableERC721Predicate.withdraw(childTokenAddr, 1)).to.be.revertedWith(
      "ChildMintableERC721Predicate: BURN_FAILED"
    );
    fakeChildERC721.burnBatch.returns(false);
    await expect(
      childMintableERC721Predicate.withdrawBatch(childTokenAddr, [accounts[0].address], [1])
    ).to.be.revertedWith("ChildMintableERC721Predicate: BURN_FAILED");
  });
});
