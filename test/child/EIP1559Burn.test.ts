import { setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber, BigNumberish } from "ethers";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { RootERC20Predicate, ChildERC20Predicate, EIP1559Burn } from "../../typechain-types";
import { alwaysFalseBytecode, alwaysTrueBytecode } from "../constants";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("EIP1559Burn", () => {
  let eip1559Burn: EIP1559Burn, accounts: SignerWithAddress[];
  before(async () => {
    accounts = await ethers.getSigners();
    const EIP1559Burn = await ethers.getContractFactory("EIP1559");
    const ChildERC20Predicate = await ethers.getContractFactory("ChildERC20Predicate");
    const childERC20Predicate = await ChildERC20Predicate.deploy();

    await childERC20Predicate.deployed();

    eip1559Burn = (await EIP1559Burn.deploy()) as EIP1559Burn;

    await eip1559Burn.deployed();
  });
});
