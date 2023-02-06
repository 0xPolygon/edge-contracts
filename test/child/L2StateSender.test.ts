import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { L2StateSender } from "../../typechain-types";

describe("L2StateSender", () => {
  let l2StateSender: L2StateSender, accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    accounts = await ethers.getSigners();
    const l2StateSenderFactory = await ethers.getContractFactory("L2StateSender");
    l2StateSender = (await l2StateSenderFactory.deploy()) as L2StateSender;

    await l2StateSender.deployed();
  });

  it("validate initialization", async () => {
    expect(await l2StateSender.MAX_LENGTH()).to.equal(2048);
    expect(await l2StateSender.counter()).to.equal(0);
  });

  it("sync state fail: exceeds max length", async () => {
    const data = ethers.utils.hexlify(ethers.utils.randomBytes(2049));
    await expect(l2StateSender.syncState(accounts[2].address, data)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");
  });

  it("sync state fail: invalid receiver", async () => {
    const data = ethers.utils.hexlify(ethers.utils.randomBytes(2048));
    await expect(l2StateSender.syncState(ethers.constants.AddressZero, data)).to.be.revertedWith("INVALID_RECEIVER");
  });

  it("sync state", async () => {
    const rounds = Math.floor(Math.random() * 10 + 2);
    let counter = 0;
    for (let i = 0; i < rounds; i++) {
      const sender = ethers.Wallet.createRandom();
      const receiver = ethers.Wallet.createRandom();
      const data = ethers.utils.hexlify(ethers.utils.randomBytes(2048));
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [sender.address],
      });
      await hre.network.provider.send("hardhat_setBalance", [
        sender.address,
        "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      ]);
      const newl2StateSender = await l2StateSender.connect(await ethers.getSigner(sender.address));
      const tx = await newl2StateSender.syncState(receiver.address, data);
      const receipt = await tx.wait();
      expect(receipt.events[0]?.args?.id).to.equal(counter + 1);
      expect(receipt.events[0]?.args?.sender).to.equal(sender.address);
      expect(receipt.events[0]?.args?.receiver).to.equal(receiver.address);
      expect(await l2StateSender.counter()).to.equal(++counter);
    }
  });
});
