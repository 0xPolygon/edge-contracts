import { setCode, impersonateAccount, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import * as hre from "hardhat";
import { ethers, network } from "hardhat";
import { AccessList } from "../../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { alwaysTrueBytecode } from "../constants";

describe("AccessList", () => {
  let accessList: AccessList,
    accounts: SignerWithAddress[];

  before(async () => {
    await hre.network.provider.send("hardhat_reset");
    accounts = await ethers.getSigners();

    await setCode("")
  })
})