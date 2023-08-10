import { ethers } from "hardhat";
import { StakeManager, TransparentUpgradeableProxy } from "../typechain-types";

async function deploy() {
  // Admin
  // FIXME: this will be public key of initial admin
  const admin = new ethers.Wallet("1f6f17db77bf966ae1bb2fa0fc32868a3d5913f1b931f085ffe6522d5966f8d3");

  // StakeToken Address
  // FIXME: this will be the IMX token address
  const stakeTokenAddress = admin.address;

  // Deploy StakeManager (implementation)
  const StakeManager = await ethers.getContractFactory("StakeManager");
  const stakeManager: StakeManager = await StakeManager.deploy();

  // Deploy proxy StakeManager and initialise
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const stakeManagerInit = stakeManager.interface.encodeFunctionData("initialize", [stakeTokenAddress]);
  const proxy: TransparentUpgradeableProxy = await Proxy.deploy(stakeManager.address, admin.address, stakeManagerInit);

  // Update genesis.json
  // - StakeManageerAddr
  // - StakeTokenAddr
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
