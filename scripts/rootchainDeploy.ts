import { ethers } from "hardhat";
const fs = require("fs");

// FILE LOCATION:
// imx-engine/services/zkevm/deploy || genesis/...
// polycore-contracts as dependency here @ given tag and release

const admin = "0xEB7FFb9fb0c80437120f6F97EdE60aB59055EAE0";

// Domain string
const DomainValidatorSetString = "DOMAIN_CHILD_VALIDATOR_SET";

// Childchain contract addresses
const ValidatorSetContract = "0x0000000000000000000000000000000000000101";

// 20
const ChildERC20Contract = "0x0000000000000000000000000000000000001003";
const ChildERC20PredicateContract = "0x0000000000000000000000000000000000001004";

// 721
const ChildERC721Contract = "0x0000000000000000000000000000000000001005";
const ChildERC721PredicateContract = "0x0000000000000000000000000000000000001006";

// 1155
const ChildERC1155Contract = "0x0000000000000000000000000000000000001007";
const ChildERC1155PredicateContract = "0x0000000000000000000000000000000000001008";

// Root mintable
const RootMintableERC20PredicateContract = "0x0000000000000000000000000000000000001009";
const RootMintableERC721PredicateContract = "0x000000000000000000000000000000000000100a";
const RootMintableERC1155PredicateContract = "0x000000000000000000000000000000000000100b";

// CLI params
// type deployParams struct {
// 	genesisPath        string <- need
// 	deployerKey        string <- hardware wallet
// 	jsonRPCAddress     string <- need
// 	stakeTokenAddr     string <- need
// 	rootERC20TokenAddr string <- not needed
// 	stakeManagerAddr   string <- need
// }

async function deploy() {
  // Get current block number for event tracker
  // FIXME: replace with Sepolia provider
  const blockNumber = await ethers.provider.getBlockNumber();

  // Deploy StateSender
  const stateSenderAddress = await deploystateSender();

  // Deploy CheckpointManager (initialisation handled in subsequent step)
  const checkpointManagerAddress = await deployCheckpointManager();

  // Deploy bls
  const blsAddress = await deployBLS();

  // Deploy bn256g2
  const bn256g2Address = await deployBN256G2();

  // Deploy ExitHelper
  const exitHelperAddress = await deployExitHelper(checkpointManagerAddress);

  // Deploy RootERC20Predicate
  const rootERC20PredicateAddress = await deployRootERC20Predicte(
    stateSenderAddress,
    exitHelperAddress,
    ChildERC20PredicateContract,
    ChildERC20Contract
  );

  // Deploy childERC20MintablePredicate
  const childERC20MintablePredicateAddress = await deployChildMintableERC20Predicate(
    stateSenderAddress,
    exitHelperAddress,
    RootMintableERC20PredicateContract
  );

  // Deploy RootERC721Predicate
  const rootERC721PredicateAddress = await deployRootERC721Predicate(
    stateSenderAddress,
    exitHelperAddress,
    ChildERC721PredicateContract,
    ChildERC721Contract
  );

  // Deploy childERC721MintablePredicate
  const childERC721MintablePredicateAddress = await deployChildMintableERC721Predicate(
    stateSenderAddress,
    exitHelperAddress,
    RootMintableERC721PredicateContract
  );

  // Deploy RootERC1155Predicate
  const rootERC1155PredicateAddress = await deployRootERC1155Predicate(
    stateSenderAddress,
    exitHelperAddress,
    ChildERC1155PredicateContract,
    ChildERC1155Contract
  );

  // Deploy childERC1155MintablePredicate
  const childERC1155MintablePredicateAddress = await deployChildMintableERC1155Predicate(
    stateSenderAddress,
    exitHelperAddress,
    RootMintableERC1155PredicateContract
  );

  // Deploy CustomSupernetManager
  const customSupernetManagerAddress = await deployCustomerSupernetManager(
    stateSenderAddress, // FIXME: this should be the stake manager address from stakemanagerDeploy.ts
    blsAddress,
    stateSenderAddress,
    blsAddress, // FIXME: this should be the stake token address which is passed in as a CLI param
    ValidatorSetContract,
    exitHelperAddress,
    DomainValidatorSetString
  );

  // Call function to emit supernetID event and consume
  // Call `StakeManager.registerChlildChain(customSupernetManagerAddr)
  // Consume `ChildManagerRegistered(id, manager)`

  // Read genesis json file
  // create bridge object and populate with the addresses derived
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function deploystateSender() {
  const StateSender = await ethers.getContractFactory("StateSender");
  const stateSender = await StateSender.deploy();
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(stateSender.address, admin, "0x");

  return proxy.address;
}

async function deployCheckpointManager() {
  const CheckpointManager = await ethers.getContractFactory("CheckpointManager");
  const checkpointManager = await CheckpointManager.deploy();
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(checkpointManager.address, admin, "0x");

  return proxy.address;
}

async function deployBLS() {
  const BLS = await ethers.getContractFactory("BLS");
  const bls = await BLS.deploy();

  return bls.address;
}

async function deployBN256G2() {
  const BN256G2 = await ethers.getContractFactory("BN256G2");
  const bn256g2 = await BN256G2.deploy();

  return bn256g2.address;
}

async function deployExitHelper(checkPointManagerAddress: string) {
  const ExitHelper = await ethers.getContractFactory("ExitHelper");
  const exitHelper = await ExitHelper.deploy();

  const exitHelperInit = exitHelper.interface.encodeFunctionData("initialize", [checkPointManagerAddress]);
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(exitHelper.address, admin, exitHelperInit);

  return proxy.address;
}

async function deployRootERC20Predicte(
  stateSenderAddress: string,
  exitHelperAddress: string,
  childERC20PredicateAddress: string,
  childTokenTemplateAddress: string
) {
  const RootERC20Predicate = await ethers.getContractFactory("RootERC20Predicate");
  const rootERC20Predicate = await RootERC20Predicate.deploy();

  // https://github.com/immutable/polygon-edge/blob/10029bcf80540174b89a8d9b622fcc82d000db2b/command/rootchain/deploy/deploy.go#L443
  // Deploy and use MockERC20 as native token address
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const mockERC20 = await MockERC20.deploy();

  const rootERC20PredicateInit = rootERC20Predicate.interface.encodeFunctionData("initialize", [
    stateSenderAddress,
    exitHelperAddress,
    childERC20PredicateAddress,
    childTokenTemplateAddress, // L2
    mockERC20.address,
  ]);
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(rootERC20Predicate.address, admin, rootERC20PredicateInit);

  return proxy.address;
}

async function deployChildMintableERC20Predicate(
  stateSenderAddress: string,
  exitHelperAddress: string,
  rootERC20PredicateAddress: string
) {
  const ChildMintableERC20Predicate = await ethers.getContractFactory("ChildMintableERC20Predicate");
  const childMintableERC20Predicate = await ChildMintableERC20Predicate.deploy();

  // L2 template deployed on L1
  const ChildERC20 = await ethers.getContractFactory("ChildERC20");
  const childERC20 = await ChildERC20.deploy();

  const childMintableERC20PredicateInit = childMintableERC20Predicate.interface.encodeFunctionData("initialize", [
    stateSenderAddress,
    exitHelperAddress,
    rootERC20PredicateAddress,
    childERC20.address,
  ]);
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(childMintableERC20Predicate.address, admin, childMintableERC20PredicateInit);

  return proxy.address;
}

async function deployRootERC721Predicate(
  stateSenderAddress: string,
  exitHelperAddress: string,
  childERC721PredicateAddress: string,
  childTokenTemplateAddress: string
) {
  const RootERC721Predicate = await ethers.getContractFactory("RootERC721Predicate");
  const rootERC721Predicate = await RootERC721Predicate.deploy();

  const rootERC721PredicateInit = rootERC721Predicate.interface.encodeFunctionData("initialize", [
    stateSenderAddress,
    exitHelperAddress,
    childERC721PredicateAddress,
    childTokenTemplateAddress,
  ]);

  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(rootERC721Predicate.address, admin, rootERC721PredicateInit);

  return proxy.address;
}

async function deployChildMintableERC721Predicate(
  stateSenderAddress: string,
  exitHelperAddress: string,
  rootERC721PredicateAddress: string
) {
  const ChildMintableERC721Predicate = await ethers.getContractFactory("ChildMintableERC721Predicate");
  const childMintableERC721Predicate = await ChildMintableERC721Predicate.deploy();

  // L2 template deployed on L1
  const ChildERC721 = await ethers.getContractFactory("ChildERC721");
  const childERC721 = await ChildERC721.deploy();

  const childMintableERC721PredicateInit = childMintableERC721Predicate.interface.encodeFunctionData("initialize", [
    stateSenderAddress,
    exitHelperAddress,
    rootERC721PredicateAddress,
    childERC721.address,
  ]);

  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(childMintableERC721Predicate.address, admin, childMintableERC721PredicateInit);

  return proxy.address;
}

async function deployRootERC1155Predicate(
  stateSenderAddress: string,
  exitHelperAddress: string,
  childERC1155PredicateAddress: string,
  childTokenTemplateAddress: string
) {
  const RootERC1155Predicate = await ethers.getContractFactory("RootERC1155Predicate");
  const rootERC1155Predicate = await RootERC1155Predicate.deploy();

  const rootERC1155PredicateInit = rootERC1155Predicate.interface.encodeFunctionData("initialize", [
    stateSenderAddress,
    exitHelperAddress,
    childERC1155PredicateAddress,
    childTokenTemplateAddress,
  ]);

  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(rootERC1155Predicate.address, admin, rootERC1155PredicateInit);

  return proxy.address;
}

async function deployChildMintableERC1155Predicate(
  stateSenderAddress: string,
  exitHelperAddress: string,
  rootERC1155PredicateAddress: string
) {
  const ChildMintableERC1155Predicate = await ethers.getContractFactory("ChildMintableERC1155Predicate");
  const childMintableERC1155Predicate = await ChildMintableERC1155Predicate.deploy();

  // L2 template deployed on L1
  const ChildERC1155 = await ethers.getContractFactory("ChildERC1155");
  const childERC1155 = await ChildERC1155.deploy();

  const childMintableERC1155PredicateInit = childMintableERC1155Predicate.interface.encodeFunctionData("initialize", [
    stateSenderAddress,
    exitHelperAddress,
    rootERC1155PredicateAddress,
    childERC1155.address,
  ]);

  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(childMintableERC1155Predicate.address, admin, childMintableERC1155PredicateInit);

  return proxy.address;
}

async function deployCustomerSupernetManager(
  stakeManagerAddress: string,
  blsAddress: string,
  stateSenderAddress: string,
  stakeTokenAddress: string,
  validatorSetContract: string,
  exitHelperAddress: string,
  newDomain: string
) {
  const CustomerSupernetManager = await ethers.getContractFactory("CustomSupernetManager");
  const customerSupernetManager = await CustomerSupernetManager.deploy();

  const customerSupernetManagerInit = customerSupernetManager.interface.encodeFunctionData("initialize", [
    stakeManagerAddress,
    blsAddress,
    stateSenderAddress,
    stakeTokenAddress,
    validatorSetContract,
    exitHelperAddress,
    newDomain,
  ]);

  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(customerSupernetManager.address, admin, customerSupernetManagerInit);

  return proxy.address;
}

async function updateGenesis(
  path: string,
  stateSenderAddress: string,
  checkpointManagerAddress: string,
  exitHelperAddress: string,
  erc20PredicateAddress: string,
  erc20ChildMinatablePredicateAddress: string,
  nativeERC20Address: string,
  erc721PredicateAddress: string,
  erc721ChildMinatablePredicateAddress: string,
  erc1155PredicateAddress: string,
  erc1155ChildMinatablePredicateAddress: string,
  childERC20Address: string,
  childERC721Address: string,
  childERC1155Address: string,
  customSupernetManagerAddress: string,
  blsAddress: string,
  bn256g2Address: string,
  startblock: number
) {
  // Read genesis json file
  // create bridge object and populate with the addresses derived
  const json = fs.readFileSync(path);
  const genesis = JSON.parse(json);
  genesis["params"]["engine"]["polybft"]["bridge"]["stakeManagerAddr"] = stakeManagerAddress;
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
