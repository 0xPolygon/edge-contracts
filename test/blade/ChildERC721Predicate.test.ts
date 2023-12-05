import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  ChildERC721Predicate,
  ChildERC721Predicate__factory,
  L2StateSender,
  L2StateSender__factory,
  StateReceiver,
  StateReceiver__factory,
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

describe("ChildERC721Predicate", () => {
  let childERC721Predicate: ChildERC721Predicate,
    systemChildERC721Predicate: ChildERC721Predicate,
    stateReceiverChildERC721Predicate: ChildERC721Predicate,
    l2StateSender: L2StateSender,
    stateReceiver: StateReceiver,
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

    const L2StateSender: L2StateSender__factory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = await L2StateSender.deploy();

    await l2StateSender.deployed();

    const StateReceiver: StateReceiver__factory = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    rootERC721Predicate = ethers.Wallet.createRandom().address;

    const ChildERC721: ChildERC721__factory = await ethers.getContractFactory("ChildERC721");
    childERC721 = await ChildERC721.deploy();

    await childERC721.deployed();

    const ChildERC721Predicate: ChildERC721Predicate__factory = await ethers.getContractFactory("ChildERC721Predicate");
    childERC721Predicate = await ChildERC721Predicate.deploy();

    await childERC721Predicate.deployed();

    impersonateAccount("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    setBalance("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE", "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    systemChildERC721Predicate = childERC721Predicate.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );

    impersonateAccount(stateReceiver.address);
    setBalance(stateReceiver.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    stateReceiverChildERC721Predicate = childERC721Predicate.connect(await ethers.getSigner(stateReceiver.address));
  });

  it("fail initialization: unauthorized", async () => {
    await expect(
      childERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    )
      .to.be.revertedWithCustomError(childERC721Predicate, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("fail bad initialization", async () => {
    await expect(
      systemChildERC721Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("ChildERC721Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await systemChildERC721Predicate.initialize(
      l2StateSender.address,
      stateReceiver.address,
      rootERC721Predicate,
      childERC721.address
    );
    expect(await childERC721Predicate.l2StateSender()).to.equal(l2StateSender.address);
    expect(await childERC721Predicate.stateReceiver()).to.equal(stateReceiver.address);
    expect(await childERC721Predicate.rootERC721Predicate()).to.equal(rootERC721Predicate);
    expect(await childERC721Predicate.childTokenTemplate()).to.equal(childERC721.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      systemChildERC721Predicate.initialize(
        l2StateSender.address,
        stateReceiver.address,
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
      childERC721Predicate.address
    );
    childToken = childERC721.attach(childTokenAddr);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST", "TEST", 18]
    );
    const mapTx = await stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log) => log.event === "L2TokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await childToken.predicate()).to.equal(childERC721Predicate.address);
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("map token fail: already mapped", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST", "TEST", 18]
    );
    await expect(
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: UNMAPPED_TOKEN");
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
    const depositTx = await stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    stopImpersonatingAccount(stateReceiverChildERC721Predicate.address);
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC721Deposit");
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
    const depositTx = await stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC721Deposit");
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
    const depositTx = await stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC721DepositBatch");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(batchDepositedTokenIds);
  });

  it("withdraw tokens from child chain with same address", async () => {
    const depositTx = await childERC721Predicate.withdraw(childTokenAddr, depositedTokenIds[0]);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC721Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(depositedTokenIds[0]);
  });

  it("withdraw tokens from child chain with different address", async () => {
    const depositTx = await childERC721Predicate
      .connect(accounts[1])
      .withdrawTo(childTokenAddr, accounts[0].address, depositedTokenIds[1]);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC721Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[1].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(depositedTokenIds[1]);
  });

  it("withdraw batch tokens fail: not contract", async () => {
    await expect(
      childERC721Predicate.withdrawBatch(ethers.Wallet.createRandom().address, [ethers.constants.AddressZero], [0])
    ).to.be.revertedWith("ChildERC721Predicate: NOT_CONTRACT");
  });

  it("withdraw batch tokens from child chain", async () => {
    const batchSize = Math.floor(Math.random() * (await childToken.balanceOf(accounts[2].address)).toNumber() + 1);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      receiverArr.push(ethers.Wallet.createRandom().address);
    }
    const depositTx = await childERC721Predicate
      .connect(accounts[2])
      .withdrawBatch(childTokenAddr, receiverArr, batchDepositedTokenIds.slice(0, batchSize));
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC721WithdrawBatch");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[2].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(batchDepositedTokenIds.slice(0, batchSize));
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
    await expect(childERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)).to.be.revertedWith(
      "ChildERC721Predicate: ONLY_STATE_RECEIVER"
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
      stateReceiverChildERC721Predicate.onStateReceive(0, ethers.Wallet.createRandom().address, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: ONLY_ROOT_PREDICATE");
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: INVALID_SIGNATURE");
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: not a contract", async () => {
    await expect(childERC721Predicate.withdraw(ethers.Wallet.createRandom().address, 1)).to.be.revertedWith(
      "ChildERC721Predicate: NOT_CONTRACT"
    );
  });

  it("fail deposit tokens of unknown child token: wrong deposit token", async () => {
    childERC721Predicate.connect(await ethers.getSigner(stateReceiver.address));
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: UNMAPPED_TOKEN");
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: UNMAPPED_TOKEN");
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC721")).deploy();
    await childToken.initialize(rootToken, "TEST", "TEST");
    await expect(stateReceiverChildERC721Predicate.withdraw(childToken.address, 0)).to.be.revertedWith(
      "ChildERC721Predicate: UNMAPPED_TOKEN"
    );
    await expect(
      childERC721Predicate.withdrawBatch(childToken.address, [ethers.constants.AddressZero], [0])
    ).to.be.revertedWith("ChildERC721Predicate: UNMAPPED_TOKEN");
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
    fakeChildERC721.predicate.returns(stateReceiverChildERC721Predicate.address);
    fakeChildERC721.mint.returns(false);
    await expect(
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: MINT_FAILED");
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
      stateReceiverChildERC721Predicate.onStateReceive(0, rootERC721Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC721Predicate: MINT_FAILED");
    fakeChildERC721.mint.returns();
  });

  it("fail withdraw tokens: burn failed", async () => {
    const fakeChildERC721 = await smock.fake<ChildERC721>("ChildERC721", {
      address: childTokenAddr,
    });
    fakeChildERC721.supportsInterface.returns(true);
    fakeChildERC721.rootToken.returns(rootToken);
    fakeChildERC721.predicate.returns(stateReceiverChildERC721Predicate.address);
    fakeChildERC721.burn.returns(false);
    await expect(stateReceiverChildERC721Predicate.withdraw(childTokenAddr, 1)).to.be.revertedWith(
      "ChildERC721Predicate: BURN_FAILED"
    );
    fakeChildERC721.burnBatch.returns(false);
    await expect(
      stateReceiverChildERC721Predicate.withdrawBatch(childTokenAddr, [accounts[0].address], [1])
    ).to.be.revertedWith("ChildERC721Predicate: BURN_FAILED");
  });
});
