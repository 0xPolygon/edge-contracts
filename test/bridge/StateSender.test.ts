import { expect } from "chai";
import { ethers } from "hardhat";
import { StateSender } from "../../typechain-types";

describe("StateSender", () => {
  let stateSender: StateSender, accounts: any[]; // we use any so we can access address directly from object

  before(async () => {
    accounts = await ethers.getSigners();
    const StateSenderFactory = await ethers.getContractFactory("StateSender");

    stateSender = (await StateSenderFactory.deploy()) as StateSender;
    await stateSender.deployed();
  });

  it("Should set initial params properly", async () => {
    expect(await stateSender.counter()).to.equal(0);
  });

  it("Should check receiver address", async () => {
    const maxDataLength = (await stateSender.MAX_LENGTH()).toNumber();
    const moreThanMaxData = "0x" + "00".repeat(maxDataLength + 1); // notice `+ 1` here (it creates more than max data)
    const receiver = "0x0000000000000000000000000000000000000000";

    await expect(stateSender.syncState(receiver, moreThanMaxData)).to.be.revertedWith("INVALID_RECEIVER");
  });

  it("Should check data length", async () => {
    const maxDataLength = (await stateSender.MAX_LENGTH()).toNumber();
    const moreThanMaxData = "0x" + "00".repeat(maxDataLength + 1); // notice `+ 1` here (it creates more than max data)
    const receiver = accounts[2].address;

    await expect(stateSender.syncState(receiver, moreThanMaxData)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");
  });

  it("Should emit event properly", async () => {
    const maxDataLength = (await stateSender.MAX_LENGTH()).toNumber();
    const maxData = "0x" + "00".repeat(maxDataLength);
    const sender = accounts[0].address;
    const receiver = accounts[1].address;

    const tx = await stateSender.syncState(receiver, maxData);
    const receipt = await tx.wait();
    expect(receipt.events?.length).to.equals(1);

    const event = receipt.events?.find((log) => log.event === "StateSynced");
    expect(event?.args?.id).to.equal(1);
    expect(event?.args?.sender).to.equal(sender);
    expect(event?.args?.receiver).to.equal(receiver);
    expect(event?.args?.data).to.equal(maxData);
  });

  it("Should increase counter properly", async () => {
    const maxDataLength = (await stateSender.MAX_LENGTH()).toNumber();
    const maxData = "0x" + "00".repeat(maxDataLength);
    const moreThanMaxData = "0x" + "00".repeat(maxDataLength + 1);
    const receiver = accounts[1].address;

    const initialCounter = (await stateSender.counter()).toNumber();
    expect(await stateSender.counter()).to.equal(initialCounter);

    await stateSender.syncState(receiver, maxData);
    await stateSender.syncState(receiver, maxData);
    await expect(stateSender.syncState(receiver, moreThanMaxData)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");
    await stateSender.syncState(receiver, maxData);
    await expect(stateSender.syncState(receiver, moreThanMaxData)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");

    expect(await stateSender.counter()).to.equal(initialCounter + 3);
  });
});
