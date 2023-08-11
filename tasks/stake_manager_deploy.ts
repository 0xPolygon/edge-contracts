import { task } from "hardhat/config";
const fs = require("fs");

// FIXME: we need to read in
// HH private key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

// npx hardhat stake_manager_deploy "./tasks/genesis_TEST_2.json" "http://127.0.0.1:8545/" "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" "0xD5bFeBDce5c91413E41cc7B24C8402c59A344f7c" "./tasks/" "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

task("stake_manager_deploy", "Deploy StakeManager")
  .addPositionalParam("genesis")
  .addPositionalParam("jsonRPC")
  .addPositionalParam("deployerKey")
  .addPositionalParam("stakeTokenAddress")
  .addPositionalParam("genesisOut")
  .addPositionalParam("adminKey")
  .setAction(async (args, hre) => {
    const ethers = hre.ethers;
    const provider = new ethers.providers.JsonRpcProvider(args.jsonRPC);
    const admin = args.adminKey;
    // Admin
    // FIXME: this will be public key of initial admin
    const deployer = new ethers.Wallet(args.deployerKey, provider);

    // StakeToken Address
    const stakeTokenAddress = args.stakeTokenAddress;

    // Deploy StakeManager
    const stakeManagerAddress = await deployStakeManager(stakeTokenAddress, admin);

    // Update genesis.json
    // - StakeManageerAddr
    updateGenesis(args.genesis, stakeManagerAddress);

    async function deployStakeManager(stakeTokenAddress: string, adminAddress: string) {
      // Deploy StakeManager (implementation)
      const StakeManager = await ethers.getContractFactory("StakeManager", deployer);
      const stakeManager = await StakeManager.deploy();

      // Deploy proxy StakeManager and initialise
      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const stakeManagerInit = stakeManager.interface.encodeFunctionData("initialize", [stakeTokenAddress]);
      const proxy = await Proxy.deploy(stakeManager.address, adminAddress, stakeManagerInit);

      return proxy.address;
    }

    function updateGenesis(path: string, stakeManagerAddress: string) {
      const json = fs.readFileSync(path);
      const genesis = JSON.parse(json);
      genesis["params"]["engine"]["polybft"]["bridge"] = { stakeManagerAddr: stakeManagerAddress };
      const updated = JSON.stringify(genesis, null, 4);

      // write the JSON to file
      fs.writeFileSync(`${args.genesisOut}/genesis.json`, updated, (error: any) => {
        if (error) {
          console.error(error);
          throw error;
        }

        console.log("Updated genesis.json with StakeManager address");
      });
    }
  });
