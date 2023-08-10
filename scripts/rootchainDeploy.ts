import { ethers } from "hardhat";
import { ExitHelper, StakeManager, TransparentUpgradeableProxy } from "../typechain-types";

const admin = "0xEB7FFb9fb0c80437120f6F97EdE60aB59055EAE0";

// Domain string
const DomainValidatorSetString = "DOMAIN_CHILD_VALIDATOR_SET";

// Childchain contract addresses
const ValidatorSetContract = "0x101";

// 20
const ChildERC20Contract = "0x1003";
const ChildERC20PredicateContract = "0x1004";

// 721
const ChildERC721Contract = "0x1005";
const ChildERC721PredicateContract = "0x1006";

// 1155
const ChildERC1155Contract = "0x1007";
const ChildERC1155PredicateContract = "0x1008";

// Root mintable
const RootMintableERC20PredicateContract = "0x1009";
const RootMintableERC721PredicateContract = "0x100a";
const RootMintableERC1155PredicateContract = "0x100b";

// CLI params
// type deployParams struct {
// 	genesisPath        string
// 	deployerKey        string
// 	jsonRPCAddress     string
// 	stakeTokenAddr     string
// 	rootERC20TokenAddr string
// 	stakeManagerAddr   string
// 	isTestMode         bool
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
  const rootERC20PredicateAddress = await deployRootERC2Predicte(
    stateSenderAddress,
    exitHelperAddress,
    ChildERC20PredicateContract,
    ChildERC20Contract,
    ethers.constants
  );
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
  const exitHelper: ExitHelper = await ExitHelper.deploy();

  const exitHelperInit = exitHelper.interface.encodeFunctionData("initialize", [checkPointManagerAddress]);
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(exitHelper.address, admin, exitHelperInit);

  return proxy.address;
}

async function deployRootERC2Predicte(
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
    childTokenTemplateAddress,
    mockERC20.address,
  ]);
  const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
  const proxy = await Proxy.deploy(rootERC20Predicate.address, admin, rootERC20PredicateInit);

  return proxy.address;
}
