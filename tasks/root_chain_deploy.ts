import { task } from "hardhat/config";
const fs = require("fs");

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

task("rootchain_deploy", "Deploy rootchain contracs")
  .addPositionalParam("genesis")
  .addPositionalParam("jsonRPC")
  .addPositionalParam("privateKey")
  .addPositionalParam("erc20Address")
  .addPositionalParam("stakeTokenAddress")
  .addPositionalParam("stakeManagerAddress")
  .addPositionalParam("genesisOut")
  .addPositionalParam("adminKey")
  .setAction(async (args, hre) => {
    const ethers = hre.ethers;
    const provider = new ethers.providers.JsonRpcProvider(args.jsonRPC);
    const admin = args.adminKey;
    const deployer = new ethers.Wallet(args.privateKey, provider);
    const stakeManagerAddress = args.stakeManagerAddress;
    const stakeTokenAddress = args.stakeTokenAddress;
    // Get current block number for event tracker
    const blockNumber = await provider.getBlockNumber();

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

    // deploy ChildERC20
    const childERC20Address = await deployChildERC20();

    // Deploy ChildERC20MintablePredicate
    const childERC20MintablePredicateAddress = await deployChildMintableERC20Predicate(
      stateSenderAddress,
      exitHelperAddress,
      RootMintableERC20PredicateContract,
      childERC20Address
    );

    // Deploy RootERC721Predicate
    const rootERC721PredicateAddress = await deployRootERC721Predicate(
      stateSenderAddress,
      exitHelperAddress,
      ChildERC721PredicateContract,
      ChildERC721Contract
    );

    // Deploy ChildERC721
    const childERC721Address = await deployChildERC721();

    // Deploy ChildERC721MintablePredicate
    const childERC721MintablePredicateAddress = await deployChildMintableERC721Predicate(
      stateSenderAddress,
      exitHelperAddress,
      RootMintableERC721PredicateContract,
      childERC721Address
    );

    // Deploy RootERC1155Predicate
    const rootERC1155PredicateAddress = await deployRootERC1155Predicate(
      stateSenderAddress,
      exitHelperAddress,
      ChildERC1155PredicateContract,
      ChildERC1155Contract
    );

    // Deploy ChildERC1155
    const childERC1155Address = await deployChildERC1155();

    // Deploy ChildERC1155MintablePredicate
    const childERC1155MintablePredicateAddress = await deployChildMintableERC1155Predicate(
      stateSenderAddress,
      exitHelperAddress,
      RootMintableERC1155PredicateContract,
      childERC1155Address
    );

    // Deploy CustomSupernetManager
    const customSupernetManagerAddress = await deployCustomerSupernetManager(
      stakeManagerAddress,
      blsAddress,
      stateSenderAddress,
      stakeTokenAddress,
      ValidatorSetContract,
      exitHelperAddress,
      DomainValidatorSetString
    );

    // Call function to emit supernetID event and consume

    // Call `StakeManager.registerChlildChain(customSupernetManagerAddr)
    // Consume `ChildManagerRegistered(id, manager)`

    const stakeManager = await ethers.getContractAt("StakeManager", stakeManagerAddress);
    const tx = await stakeManager.connect(deployer).registerChildChain(customSupernetManagerAddress);
    const receipt = await tx.wait();
    let supernetID: number = 0;
    for (var log in receipt.logs) {
      let parsedLog = stakeManager.interface.parseLog(receipt.logs[log]);
      if (parsedLog.name == "ChildManagerRegistered") {
        supernetID = parsedLog.args[0].toNumber();
        break;
      }
    }
    // Read genesis json file
    // create bridge object and populate with the addresses derived
    console.log("Successfully deployed contracts. Updating JSON");

    updateGenesis(
      "./scripts/genesis.json",
      stateSenderAddress,
      checkpointManagerAddress,
      exitHelperAddress,
      rootERC20PredicateAddress,
      childERC20MintablePredicateAddress,
      ChildERC20Contract,
      rootERC721PredicateAddress,
      childERC721MintablePredicateAddress,
      rootERC1155PredicateAddress,
      childERC1155MintablePredicateAddress,
      childERC20Address,
      childERC721Address,
      childERC1155Address,
      customSupernetManagerAddress,
      blsAddress,
      bn256g2Address,
      blockNumber,
      supernetID
    );

    async function deploystateSender() {
      const StateSender = await ethers.getContractFactory("StateSender", deployer);
      const stateSender = await StateSender.deploy();
      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(stateSender.address, admin, "0x");

      return proxy.address;
    }

    async function deployCheckpointManager() {
      const CheckpointManager = await ethers.getContractFactory("CheckpointManager", deployer);
      const checkpointManager = await CheckpointManager.deploy();
      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(checkpointManager.address, admin, "0x");

      return proxy.address;
    }

    async function deployBLS() {
      const BLS = await ethers.getContractFactory("BLS", deployer);
      const bls = await BLS.deploy();

      return bls.address;
    }

    async function deployBN256G2() {
      const BN256G2 = await ethers.getContractFactory("BN256G2", deployer);
      const bn256g2 = await BN256G2.deploy();

      return bn256g2.address;
    }

    async function deployExitHelper(checkPointManagerAddress: string) {
      const ExitHelper = await ethers.getContractFactory("ExitHelper", deployer);
      const exitHelper = await ExitHelper.deploy();

      const exitHelperInit = exitHelper.interface.encodeFunctionData("initialize", [checkPointManagerAddress]);
      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(exitHelper.address, admin, exitHelperInit);

      return proxy.address;
    }

    async function deployRootERC20Predicte(
      stateSenderAddress: string,
      exitHelperAddress: string,
      childERC20PredicateAddress: string,
      childTokenTemplateAddress: string
    ) {
      const RootERC20Predicate = await ethers.getContractFactory("RootERC20Predicate", deployer);
      const rootERC20Predicate = await RootERC20Predicate.deploy();

      // https://github.com/immutable/polygon-edge/blob/10029bcf80540174b89a8d9b622fcc82d000db2b/command/rootchain/deploy/deploy.go#L443
      // Deploy and use MockERC20 as native token address
      const MockERC20 = await ethers.getContractFactory("MockERC20", deployer);
      const mockERC20 = await MockERC20.deploy();

      const rootERC20PredicateInit = rootERC20Predicate.interface.encodeFunctionData("initialize", [
        stateSenderAddress,
        exitHelperAddress,
        childERC20PredicateAddress,
        childTokenTemplateAddress, // L2
        mockERC20.address,
      ]);
      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(rootERC20Predicate.address, admin, rootERC20PredicateInit);

      return proxy.address;
    }

    async function deployChildERC20() {
      // L2 template deployed on L1
      const ChildERC20 = await ethers.getContractFactory("ChildERC20", deployer);
      const childERC20 = await ChildERC20.deploy();

      return childERC20.address;
    }

    async function deployChildMintableERC20Predicate(
      stateSenderAddress: string,
      exitHelperAddress: string,
      rootERC20PredicateAddress: string,
      childERC20Address: string
    ) {
      const ChildMintableERC20Predicate = await ethers.getContractFactory("ChildMintableERC20Predicate", deployer);
      const childMintableERC20Predicate = await ChildMintableERC20Predicate.deploy();

      const childMintableERC20PredicateInit = childMintableERC20Predicate.interface.encodeFunctionData("initialize", [
        stateSenderAddress,
        exitHelperAddress,
        rootERC20PredicateAddress,
        childERC20Address,
      ]);
      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(childMintableERC20Predicate.address, admin, childMintableERC20PredicateInit);

      return proxy.address;
    }

    async function deployRootERC721Predicate(
      stateSenderAddress: string,
      exitHelperAddress: string,
      childERC721PredicateAddress: string,
      childTokenTemplateAddress: string
    ) {
      const RootERC721Predicate = await ethers.getContractFactory("RootERC721Predicate", deployer);
      const rootERC721Predicate = await RootERC721Predicate.deploy();

      const rootERC721PredicateInit = rootERC721Predicate.interface.encodeFunctionData("initialize", [
        stateSenderAddress,
        exitHelperAddress,
        childERC721PredicateAddress,
        childTokenTemplateAddress,
      ]);

      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(rootERC721Predicate.address, admin, rootERC721PredicateInit);

      return proxy.address;
    }

    async function deployChildERC721() {
      // L2 template deployed on L1
      const ChildERC721 = await ethers.getContractFactory("ChildERC721", deployer);
      const childERC721 = await ChildERC721.deploy();

      return childERC721.address;
    }

    async function deployChildMintableERC721Predicate(
      stateSenderAddress: string,
      exitHelperAddress: string,
      rootERC721PredicateAddress: string,
      childERC721Address: string
    ) {
      const ChildMintableERC721Predicate = await ethers.getContractFactory("ChildMintableERC721Predicate", deployer);
      const childMintableERC721Predicate = await ChildMintableERC721Predicate.deploy();

      const childMintableERC721PredicateInit = childMintableERC721Predicate.interface.encodeFunctionData("initialize", [
        stateSenderAddress,
        exitHelperAddress,
        rootERC721PredicateAddress,
        childERC721Address,
      ]);

      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(childMintableERC721Predicate.address, admin, childMintableERC721PredicateInit);

      return proxy.address;
    }

    async function deployRootERC1155Predicate(
      stateSenderAddress: string,
      exitHelperAddress: string,
      childERC1155PredicateAddress: string,
      childTokenTemplateAddress: string
    ) {
      const RootERC1155Predicate = await ethers.getContractFactory("RootERC1155Predicate", deployer);
      const rootERC1155Predicate = await RootERC1155Predicate.deploy();

      const rootERC1155PredicateInit = rootERC1155Predicate.interface.encodeFunctionData("initialize", [
        stateSenderAddress,
        exitHelperAddress,
        childERC1155PredicateAddress,
        childTokenTemplateAddress,
      ]);

      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
      const proxy = await Proxy.deploy(rootERC1155Predicate.address, admin, rootERC1155PredicateInit);

      return proxy.address;
    }

    async function deployChildERC1155() {
      // L2 template deployed on L1
      const ChildERC1155 = await ethers.getContractFactory("ChildERC1155", deployer);
      const childERC1155 = await ChildERC1155.deploy();

      return childERC1155.address;
    }

    async function deployChildMintableERC1155Predicate(
      stateSenderAddress: string,
      exitHelperAddress: string,
      rootERC1155PredicateAddress: string,
      childERC1155Address: string
    ) {
      const ChildMintableERC1155Predicate = await ethers.getContractFactory("ChildMintableERC1155Predicate", deployer);
      const childMintableERC1155Predicate = await ChildMintableERC1155Predicate.deploy();

      const childMintableERC1155PredicateInit = childMintableERC1155Predicate.interface.encodeFunctionData(
        "initialize",
        [stateSenderAddress, exitHelperAddress, rootERC1155PredicateAddress, childERC1155Address]
      );

      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
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
      const CustomerSupernetManager = await ethers.getContractFactory("CustomSupernetManager", deployer);
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

      const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer);
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
      startblock: number,
      supernetID: number
    ) {
      // Read genesis json file
      const json = fs.readFileSync(path);
      const genesis = JSON.parse(json);
      if (genesis["params"]["engine"]["polybft"]["bridge"] == undefined) {
        console.error("genesis.json does not contain a bridge object");
      }

      genesis["params"]["engine"]["polybft"]["bridge"]["stateSenderAddress"] = stateSenderAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["checkpointManagerAddress"] = checkpointManagerAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["exitHelperAddress"] = exitHelperAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["erc20PredicateAddress"] = erc20PredicateAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["erc20ChildMinatablePredicateAddress"] =
        erc20ChildMinatablePredicateAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["nativeERC20Address"] = nativeERC20Address;
      genesis["params"]["engine"]["polybft"]["bridge"]["erc721PredicateAddress"] = erc721PredicateAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["erc721ChildMinatablePredicateAddress"] =
        erc721ChildMinatablePredicateAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["erc1155PredicateAddress"] = erc1155PredicateAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["erc1155ChildMinatablePredicateAddress"] =
        erc1155ChildMinatablePredicateAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["childERC20Address"] = childERC20Address;
      genesis["params"]["engine"]["polybft"]["bridge"]["childERC721Address"] = childERC721Address;
      genesis["params"]["engine"]["polybft"]["bridge"]["childERC1155Address"] = childERC1155Address;
      genesis["params"]["engine"]["polybft"]["bridge"]["customSupernetManagerAddress"] = customSupernetManagerAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["blsAddress"] = blsAddress;
      genesis["params"]["engine"]["polybft"]["bridge"]["bn256g2Address"] = bn256g2Address;
      genesis["params"]["engine"]["polybft"]["bridge"]["eventTrackerStartBlocks"] = { stateSenderAddress: startblock };
      genesis["params"]["engine"]["polybft"]["supernetID"] = supernetID;

      const updated = JSON.stringify(genesis, null, 4);

      // write the JSON to file
      fs.writeFileSync("./scripts/genesis.json", updated, (error: any) => {
        if (error) {
          console.error(error);
          throw error;
        }

        console.log("Updated genesis.json with roothchain deployment addresses");
      });
    }
  });
