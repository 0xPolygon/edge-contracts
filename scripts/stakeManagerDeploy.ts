import { ethers } from "hardhat";
import { StakeManager, TransparentUpgradeableProxy } from "../typechain-types";
const fs = require("fs");

// FIXME: we need to read in

async function deploy() {
  // Admin
  // FIXME: this will be public key of initial admin
  const admin = new ethers.Wallet("1f6f17db77bf966ae1bb2fa0fc32868a3d5913f1b931f085ffe6522d5966f8d3");

  // StakeToken Address
  // FIXME: this will be the IMX token address
  const stakeTokenAddress = admin.address;

  // Deploy StakeManager
  const stakeManagerAddress = await deployStakeManager(stakeTokenAddress, admin.address);

  // Update genesis.json
  // - StakeManageerAddr
  updateGenesis("./scripts/genesis_TEST_2.json", stakeManagerAddress);
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function deployStakeManager(stakeTokenAddress: string, adminAddress: string) {
  // Deploy StakeManager (implementation)
  const StakeManager = await ethers.getContractFactory("StakeManager");
  const stakeManager: StakeManager = await StakeManager.deploy();

  // Deploy proxy StakeManager and initialise
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const stakeManagerInit = stakeManager.interface.encodeFunctionData("initialize", [stakeTokenAddress]);
  const proxy: TransparentUpgradeableProxy = await Proxy.deploy(stakeManager.address, adminAddress, stakeManagerInit);

  return proxy.address;
}

function updateGenesis(path: string, stakeManagerAddress: string) {
  const json = fs.readFileSync(path);
  const genesis = JSON.parse(json);
  genesis["params"]["engine"]["polybft"]["bridge"] = { stakeManagerAddr: stakeManagerAddress };
  // genesis["params"]["engine"]["polybft"]["bridge"]["stakeManagerAddr"] = stakeManagerAddress;
  const updated = JSON.stringify(genesis, null, 4);

  // write the JSON to file
  fs.writeFile("./scripts/genesis.json", updated, (error: any) => {
    if (error) {
      console.error(error);
      throw error;
    }

    console.log("Updated genesis.json with StakeManager address");
  });
}
