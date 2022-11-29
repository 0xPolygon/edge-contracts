import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockOwned } from "../../typechain";
import { customError } from "../util";

describe("Owned", () => {
  let owned: MockOwned;
  let accounts: SignerWithAddress[];

  before(async () => {
    accounts = await ethers.getSigners();
    const factory = await ethers.getContractFactory("MockOwned");
    owned = (await upgrades.deployProxy(factory, [], { unsafeAllow: ["delegatecall"] })) as MockOwned;
  });

  it("only owner should be able to propose a new owner", async () => {
    await expect(owned.connect(accounts[1]).proposeOwner(accounts[1].address)).to.be.revertedWith(
      customError("Unauthorized", "OWNER")
    );
  });

  it("owner should be able to propose a new owner", async () => {
    expect(await owned.proposedOwner()).to.equal("0x0000000000000000000000000000000000000000");
    await owned.proposeOwner(accounts[1].address);
    expect(await owned.proposedOwner()).to.equal(accounts[1].address);
  });

  it("only proposed owner should be able to accept ownership", async () => {
    expect(await owned.owner()).to.equal(accounts[0].address);
    await expect(owned.claimOwnership()).to.be.revertedWith(customError("Unauthorized", "PROPOSED_OWNER"));
    await expect(owned.connect(accounts[2]).claimOwnership()).to.be.revertedWith(
      customError("Unauthorized", "PROPOSED_OWNER")
    );
    await expect(owned.connect(accounts[1]).claimOwnership())
      .to.emit(owned, "OwnershipTransferred")
      .withArgs(accounts[0].address, accounts[1].address);
    expect(await owned.owner()).to.equal(accounts[1].address);
  });
});
