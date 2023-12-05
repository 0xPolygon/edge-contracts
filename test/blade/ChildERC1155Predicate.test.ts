import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import {
  ChildERC1155Predicate,
  ChildERC1155Predicate__factory,
  L2StateSender,
  L2StateSender__factory,
  StateReceiver,
  StateReceiver__factory,
  ChildERC1155,
  ChildERC1155__factory,
} from "../../typechain-types";
import { setBalance, impersonateAccount, stopImpersonatingAccount } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { smock } from "@defi-wonderland/smock";

describe("ChildERC1155Predicate", () => {
  let childERC1155Predicate: ChildERC1155Predicate,
    systemChildERC1155Predicate: ChildERC1155Predicate,
    stateReceiverChildERC1155Predicate: ChildERC1155Predicate,
    l2StateSender: L2StateSender,
    stateReceiver: StateReceiver,
    rootERC1155Predicate: string,
    childERC1155: ChildERC1155,
    rootToken: string,
    childTokenAddr: string,
    depositedTokenIds: number[] = [],
    batchDepositedTokenIds: number[] = [],
    batchDepositedTokenAmounts: BigNumber[] = [],
    accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();

    const L2StateSender: L2StateSender__factory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = await L2StateSender.deploy();

    await l2StateSender.deployed();

    const StateReceiver: StateReceiver__factory = await ethers.getContractFactory("StateReceiver");
    stateReceiver = await StateReceiver.deploy();

    await stateReceiver.deployed();

    rootERC1155Predicate = ethers.Wallet.createRandom().address;

    const ChildERC1155: ChildERC1155__factory = await ethers.getContractFactory("ChildERC1155");
    childERC1155 = await ChildERC1155.deploy();

    await childERC1155.deployed();

    const ChildERC1155Predicate: ChildERC1155Predicate__factory = await ethers.getContractFactory(
      "ChildERC1155Predicate"
    );
    childERC1155Predicate = await ChildERC1155Predicate.deploy();

    await childERC1155Predicate.deployed();

    impersonateAccount("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    setBalance("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE", "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    systemChildERC1155Predicate = childERC1155Predicate.connect(
      await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE")
    );

    impersonateAccount(stateReceiver.address);
    setBalance(stateReceiver.address, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    stateReceiverChildERC1155Predicate = childERC1155Predicate.connect(await ethers.getSigner(stateReceiver.address));
  });

  it("fail initialization: unauthorized", async () => {
    await expect(
      childERC1155Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    )
      .to.be.revertedWithCustomError(childERC1155Predicate, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("fail bad initialization", async () => {
    await expect(
      systemChildERC1155Predicate.initialize(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
      )
    ).to.be.revertedWith("ChildERC1155Predicate: BAD_INITIALIZATION");
  });

  it("initialize and validate initialization", async () => {
    await systemChildERC1155Predicate.initialize(
      l2StateSender.address,
      stateReceiver.address,
      rootERC1155Predicate,
      childERC1155.address
    );
    expect(await childERC1155Predicate.l2StateSender()).to.equal(l2StateSender.address);
    expect(await childERC1155Predicate.stateReceiver()).to.equal(stateReceiver.address);
    expect(await childERC1155Predicate.rootERC1155Predicate()).to.equal(rootERC1155Predicate);
    expect(await childERC1155Predicate.childTokenTemplate()).to.equal(childERC1155.address);
  });

  it("fail reinitialization", async () => {
    await expect(
      systemChildERC1155Predicate.initialize(
        l2StateSender.address,
        stateReceiver.address,
        rootERC1155Predicate,
        childERC1155.address
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("map token success", async () => {
    rootToken = ethers.Wallet.createRandom().address;
    const clonesContract = await (await ethers.getContractFactory("MockClones")).deploy();
    childTokenAddr = await clonesContract.predictDeterministicAddress(
      childERC1155.address,
      ethers.utils.solidityKeccak256(["address"], [rootToken]),
      childERC1155Predicate.address
    );
    const childToken = childERC1155.attach(childTokenAddr);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST1", "TEST1", 18]
    );
    const mapTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const mapReceipt = await mapTx.wait();
    const mapEvent = mapReceipt?.events?.find((log) => log.event === "L2TokenMapped");
    expect(mapEvent?.args?.rootToken).to.equal(rootToken);
    expect(mapEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(await childToken.predicate()).to.equal(childERC1155Predicate.address);
    expect(await childToken.rootToken()).to.equal(rootToken);
  });

  it("map token fail: invalid root token", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [
        ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]),
        "0x0000000000000000000000000000000000000000",
        "TEST1",
        "TEST1",
        18,
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("map token fail: already mapped", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "string", "uint8"],
      [ethers.utils.solidityKeccak256(["string"], ["MAP_TOKEN"]), rootToken, "TEST1", "TEST1", 18]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWithPanic();
  });

  it("deposit tokens from root chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    depositedTokenIds.push(randomAmount);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[0].address,
        randomAmount,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const depositTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    stopImpersonatingAccount(stateReceiverChildERC1155Predicate.address);
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC1155Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(randomAmount);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("deposit tokens from root chain with different address", async () => {
    const randomAmount = Math.floor(Math.random() * 1000000 + 1);
    depositedTokenIds.push(randomAmount);
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[1].address,
        randomAmount,
        ethers.utils.parseUnits(String(randomAmount)),
      ]
    );
    const depositTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC1155Deposit");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[1].address);
    expect(depositEvent?.args?.tokenId).to.equal(randomAmount);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("batch deposit tokens from root chain: success", async () => {
    const batchSize = Math.floor(Math.random() * 10 + 2);
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      const randomAmount = Math.floor(Math.random() * 1000000 + 1);
      batchDepositedTokenIds.push(randomAmount);
      receiverArr.push(accounts[2].address);
    }
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT_BATCH"]),
        rootToken,
        accounts[0].address,
        receiverArr,
        batchDepositedTokenIds,
        batchDepositedTokenIds.map((tokenId) => ethers.utils.parseUnits(String(tokenId))),
      ]
    );
    const depositTx = await stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData);
    const depositReceipt = await depositTx.wait();
    stopImpersonatingAccount(stateReceiverChildERC1155Predicate.address);
    const depositEvent = depositReceipt.events?.find((log) => log.event === "L2ERC1155DepositBatch");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(batchDepositedTokenIds);
    expect(depositEvent?.args?.amounts).to.deep.equal(
      batchDepositedTokenIds.map((tokenId) => ethers.utils.parseUnits(String(tokenId)))
    );
  });

  it("withdraw tokens from child chain with same address", async () => {
    const randomAmount = Math.floor(Math.random() * depositedTokenIds[0] + 1);
    const depositTx = await childERC1155Predicate.withdraw(
      childTokenAddr,
      depositedTokenIds[0],
      ethers.utils.parseUnits(String(randomAmount))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC1155Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[0].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(depositedTokenIds[0]);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("withdraw tokens from child chain with different address", async () => {
    const randomAmount = Math.floor(Math.random() * depositedTokenIds[1] + 1);
    const depositTx = await childERC1155Predicate
      .connect(accounts[1])
      .withdrawTo(
        childTokenAddr,
        accounts[0].address,
        depositedTokenIds[1],
        ethers.utils.parseUnits(String(randomAmount))
      );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC1155Withdraw");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[1].address);
    expect(depositEvent?.args?.receiver).to.equal(accounts[0].address);
    expect(depositEvent?.args?.tokenId).to.equal(depositedTokenIds[1]);
    expect(depositEvent?.args?.amount).to.equal(ethers.utils.parseUnits(String(randomAmount)));
  });

  it("batch withdraw tokens from child chain: success", async () => {
    const batchSize = Math.max(1, Math.floor(Math.random() * batchDepositedTokenIds.length));
    const receiverArr = [];
    for (let i = 0; i < batchSize; i++) {
      receiverArr.push(accounts[1].address);
    }
    batchDepositedTokenAmounts = batchDepositedTokenIds.map((tokenId) => ethers.utils.parseUnits(String(tokenId)));
    const depositTx = await childERC1155Predicate.connect(accounts[2]).withdrawBatch(
      childTokenAddr,
      receiverArr,
      batchDepositedTokenIds.slice(0, batchSize),
      batchDepositedTokenIds.slice(0, batchSize).map((tokenId) => ethers.utils.parseUnits(String(tokenId)))
    );
    const depositReceipt = await depositTx.wait();
    const depositEvent = depositReceipt.events?.find((log: any) => log.event === "L2ERC1155WithdrawBatch");
    expect(depositEvent?.args?.rootToken).to.equal(rootToken);
    expect(depositEvent?.args?.childToken).to.equal(childTokenAddr);
    expect(depositEvent?.args?.sender).to.equal(accounts[2].address);
    expect(depositEvent?.args?.receivers).to.deep.equal(receiverArr);
    expect(depositEvent?.args?.tokenIds).to.deep.equal(batchDepositedTokenIds.slice(0, batchSize));
    expect(depositEvent?.args?.amounts).to.deep.equal(
      batchDepositedTokenIds.slice(0, batchSize).map((tokenId) => ethers.utils.parseUnits(String(tokenId)))
    );
  });

  it("fail deposit tokens: only state receiver", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        0,
        0,
      ]
    );
    await expect(childERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)).to.be.revertedWith(
      "ChildERC1155Predicate: ONLY_STATE_RECEIVER"
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
      stateReceiverChildERC1155Predicate.onStateReceive(0, ethers.Wallet.createRandom().address, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: ONLY_ROOT_PREDICATE");
  });

  it("fail deposit tokens: invalid signature", async () => {
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [ethers.utils.randomBytes(32), ethers.constants.AddressZero, accounts[0].address, accounts[0].address, 0, 0]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: INVALID_SIGNATURE");
  });

  it("fail deposit tokens of unknown child token: unmapped token", async () => {
    let stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        0,
        0,
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: not a contract", async () => {
    await expect(childERC1155Predicate.withdraw(ethers.Wallet.createRandom().address, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: NOT_CONTRACT"
    );
    await expect(
      childERC1155Predicate.withdrawBatch(
        ethers.Wallet.createRandom().address,
        [ethers.constants.AddressZero],
        [0],
        [1]
      )
    ).to.be.revertedWith("ChildERC1155Predicate: NOT_CONTRACT");
  });

  it("fail deposit tokens of unknown child token: wrong deposit token", async () => {
    childERC1155Predicate.connect(await ethers.getSigner(stateReceiver.address));
    const stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        "0x0000000000000000000000000000000000000000",
        accounts[0].address,
        accounts[0].address,
        0,
        0,
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  it("fail deposit tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC1155")).deploy();
    await childToken.initialize(rootToken, "TEST");
    let stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        ethers.Wallet.createRandom().address,
        accounts[0].address,
        accounts[0].address,
        0,
        0,
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
    stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT_BATCH"]),
        ethers.Wallet.createRandom().address,
        accounts[0].address,
        [accounts[0].address],
        [0],
        [0],
      ]
    );
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  it("fail withdraw tokens of unknown child token: unmapped token", async () => {
    const rootToken = ethers.Wallet.createRandom().address;
    const childToken = await (await ethers.getContractFactory("ChildERC1155")).deploy();
    await childToken.initialize(rootToken, "TEST");
    await expect(stateReceiverChildERC1155Predicate.withdraw(childToken.address, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: UNMAPPED_TOKEN"
    );
    await expect(
      stateReceiverChildERC1155Predicate.withdrawBatch(childToken.address, [ethers.constants.AddressZero], [0], [1])
    ).to.be.revertedWith("ChildERC1155Predicate: UNMAPPED_TOKEN");
  });

  // since we fake NativeERC20 here, keep this function last:
  it("fail deposit tokens: mint failed", async () => {
    let stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address", "uint256", "uint256"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT"]),
        rootToken,
        accounts[0].address,
        accounts[0].address,
        1,
        1,
      ]
    );
    const fakeERC1155 = await smock.fake<ChildERC1155>("ChildERC1155", {
      address: childTokenAddr,
    });
    fakeERC1155.supportsInterface.returns(true);
    fakeERC1155.rootToken.returns(rootToken);
    fakeERC1155.predicate.returns(childERC1155Predicate.address);
    fakeERC1155.mint.returns(false);
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: MINT_FAILED");
    stateSyncData = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "address", "address[]", "uint256[]", "uint256[]"],
      [
        ethers.utils.solidityKeccak256(["string"], ["DEPOSIT_BATCH"]),
        rootToken,
        accounts[0].address,
        [accounts[0].address],
        [1],
        [1],
      ]
    );
    fakeERC1155.mintBatch.returns(false);
    await expect(
      stateReceiverChildERC1155Predicate.onStateReceive(0, rootERC1155Predicate, stateSyncData)
    ).to.be.revertedWith("ChildERC1155Predicate: MINT_FAILED");
  });

  it("fail withdraw tokens: burn failed", async () => {
    const fakeERC1155 = await smock.fake<ChildERC1155>("ChildERC1155", {
      address: childTokenAddr,
    });
    fakeERC1155.supportsInterface.returns(true);
    fakeERC1155.rootToken.returns(rootToken);
    fakeERC1155.predicate.returns(childERC1155Predicate.address);
    fakeERC1155.burn.returns(false);
    await expect(stateReceiverChildERC1155Predicate.withdraw(childTokenAddr, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: BURN_FAILED"
    );
    fakeERC1155.burnBatch.returns(false);
    await expect(
      stateReceiverChildERC1155Predicate.withdrawBatch(childTokenAddr, [ethers.constants.AddressZero], [0], [1])
    ).to.be.revertedWith("ChildERC1155Predicate: BURN_FAILED");
  });

  it("fail withdraw tokens: bad interface", async () => {
    const fakeERC1155 = await smock.fake<ChildERC1155>("ChildERC1155", {
      address: childTokenAddr,
    });
    fakeERC1155.supportsInterface.reverts();
    await expect(stateReceiverChildERC1155Predicate.withdraw(childTokenAddr, 0, 1)).to.be.revertedWith(
      "ChildERC1155Predicate: NOT_CONTRACT"
    );
  });
});
