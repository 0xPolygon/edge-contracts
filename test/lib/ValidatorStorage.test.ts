import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { MockValidatorStorage } from "../../typechain-types";

describe("ValidatorStorage", async () => {
  let accounts: SignerWithAddress[];
  let vs: MockValidatorStorage;

  before(async () => {
    accounts = await ethers.getSigners();
    vs = await (await ethers.getContractFactory("MockValidatorStorage")).deploy() as MockValidatorStorage;
  });

  it("should be able to insert values", async () => {
    await vs.insert(accounts[0].address, 100);
    await vs.insert(accounts[1].address, 200);

    expect(await vs.activeValidators()).to.deep.equal([accounts[1].address, accounts[0].address]);
  });

  it("should report min and max values correctly", async () => {
    const min = await vs.min();
    const max = await vs.max();

    expect(min.balance).to.equal(100);
    expect(min.account).to.equal(accounts[0].address);
    expect(max.balance).to.equal(200);
    expect(max.account).to.equal(accounts[1].address);
  });

  it("should be able to remove accounts", async () => {
    await vs.remove(accounts[0].address);

    const min = await vs.min();
    const max = await vs.max();

    expect(min.balance).to.equal(200);
    expect(min.account).to.equal(accounts[1].address);
    expect(max.balance).to.equal(200);
    expect(max.account).to.equal(accounts[1].address);
  });

  it("should be able to return n amount of largest stakers", async () => {
    for (let i = 2; i < accounts.length; i++) {
      // generate random integer between 50 and 1000
      const balance = Math.floor(Math.random() * (1000 - 50 + 1)) + 50;
      await vs.insert(accounts[i].address, balance);
    }

    const activeValidators = await vs.activeValidators();

    expect(activeValidators.length).to.equal(await vs.ACTIVE_VALIDATORS());
  });

  it("should be able to return all validators", async () => {
    const allValidators = await Promise.all(
      (
        await vs.allValidators()
      ).map(async (v) => ({
        validator: v,
        balance: await vs.balanceOf(v),
      }))
    );

    let previousBalance = BigNumber.from(10000);
    for (const validator of allValidators) {
      expect(validator.balance.lte(previousBalance)).to.be.true;
      previousBalance = validator.balance;
    }
  });

  it("should be able to remove all validators", async () => {
    const allValidators = await vs.allValidators();
    for (const validator of allValidators) {
      await vs.remove(validator);
    }
    expect(await vs.activeValidators()).to.deep.equal([]);
  });
});
