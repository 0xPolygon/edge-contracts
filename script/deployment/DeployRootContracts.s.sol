// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/root/staking/DeployStakeManager.s.sol";
import "script/deployment/root/DeployStateSender.s.sol";
import "script/deployment/root/DeployCheckpointManager.s.sol";
import "script/deployment/root/DeployExitHelper.s.sol";
import "script/deployment/root/staking/DeployCustomSupernetManager.s.sol";
import "script/deployment/root/DeployRootERC20Predicate.s.sol";
import "script/deployment/root/DeployChildMintableERC20Predicate.s.sol";
import "script/deployment/root/DeployRootERC721Predicate.s.sol";
import "script/deployment/root/DeployChildMintableERC721Predicate.s.sol";
import "script/deployment/root/DeployRootERC1155Predicate.s.sol";
import "script/deployment/root/DeployChildMintableERC1155Predicate.s.sol";

contract DeployRootContracts is
    StakeManagerDeployer,
    StateSenderDeployer,
    CheckpointManagerDeployer,
    ExitHelperDeployer,
    CustomSupernetManagerDeployer,
    RootERC20PredicateDeployer,
    ChildMintableERC20PredicateDeployer,
    RootERC721PredicateDeployer,
    ChildMintableERC721PredicateDeployer,
    RootERC1155PredicateDeployer,
    ChildMintableERC1155PredicateDeployer
{
    using stdJson for string;

    address proxyAdmin;

    address stakeManagerLogic;
    address stakeManagerProxy;
    address stateSenderLogic;
    address checkpointManagerLogic;
    address checkpointManagerProxy;
    address exitHelperLogic;
    address exitHelperProxy;
    address customSupernetManagerLogic;
    address customSupernetManagerProxy;
    address rootERC20PredicateLogic;
    address rootERC20PredicateProxy;
    address childMintableERC20PredicateLogic;
    address childMintableERC20PredicateProxy;
    address rootERC721PredicateLogic;
    address rootERC721PredicateProxy;
    address childMintableERC721PredicateLogic;
    address childMintableERC721PredicateProxy;
    address rootERC1155PredicateLogic;
    address rootERC1155PredicateProxy;
    address childMintableERC1155PredicateLogic;
    address childMintableERC1155PredicateProxy;

    function run() external {
        string memory config = vm.readFile("script/deployment/deployRootContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["common"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        (stakeManagerLogic, stakeManagerProxy) = deployStakeManager(
            proxyAdmin,
            config.readAddress('["StakeManager"].newStakingToken')
        );

        stateSenderLogic = deployStateSender();

        (checkpointManagerLogic, checkpointManagerProxy) = deployCheckpointManager(
            proxyAdmin,
            IBLS(config.readAddress('["common"].newBls')),
            IBN256G2(config.readAddress('["CheckpointManager"].newBn256G2')),
            config.readUint('["CheckpointManager"].chainId_'),
            abi.decode(config.readBytes('["CheckpointManager"].newValidatorSet'), (ICheckpointManager.Validator[]))
        );

        (exitHelperLogic, exitHelperProxy) = deployExitHelper(proxyAdmin, ICheckpointManager(checkpointManagerProxy));

        (customSupernetManagerLogic, customSupernetManagerProxy) = deployCustomSupernetManager(
            proxyAdmin,
            stakeManagerProxy,
            config.readAddress('["common"].newBls'),
            stateSenderLogic,
            config.readAddress('["CustomSupernetManager"].newMatic'),
            config.readAddress('["CustomSupernetManager"].newChildValidatorSet'),
            exitHelperProxy,
            config.readString('["CustomSupernetManager"].newDomain')
        );

        (rootERC20PredicateLogic, rootERC20PredicateProxy) = deployRootERC20Predicate(
            proxyAdmin,
            stateSenderLogic,
            exitHelperProxy,
            config.readAddress('["RootERC20Predicate"].newChildERC20Predicate'),
            config.readAddress('["common"].newChildTokenTemplate'),
            config.readAddress('["RootERC20Predicate"].nativeTokenRootAddress')
        );

        (childMintableERC20PredicateLogic, childMintableERC20PredicateProxy) = deployChildMintableERC20Predicate(
            proxyAdmin,
            stateSenderLogic,
            exitHelperProxy,
            rootERC20PredicateProxy,
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (rootERC721PredicateLogic, rootERC721PredicateProxy) = deployRootERC721Predicate(
            proxyAdmin,
            stateSenderLogic,
            exitHelperProxy,
            config.readAddress('["RootERC721Predicate"].newChildERC721Predicate'),
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (childMintableERC721PredicateLogic, childMintableERC721PredicateProxy) = deployChildMintableERC721Predicate(
            proxyAdmin,
            stateSenderLogic,
            exitHelperProxy,
            rootERC721PredicateProxy,
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (rootERC1155PredicateLogic, rootERC1155PredicateProxy) = deployRootERC1155Predicate(
            proxyAdmin,
            stateSenderLogic,
            exitHelperProxy,
            config.readAddress('["RootERC1155Predicate"].newChildERC1155Predicate'),
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (childMintableERC1155PredicateLogic, childMintableERC1155PredicateProxy) = deployChildMintableERC1155Predicate(
            proxyAdmin,
            stateSenderLogic,
            exitHelperProxy,
            rootERC1155PredicateProxy,
            config.readAddress('["common"].newChildTokenTemplate')
        );

        console.log("Simulating...");
        console.log("");
        console.log("Expected addresses:");
        console.log("");
        console.log("ProxyAdmin");
        console.log("");
        console.log("Logic:", proxyAdmin);
        console.log("Proxy:", "Does not have a proxy");
        console.log("");
        console.log("");
        console.log("StakeManager");
        console.log("");
        console.log("Logic:", stakeManagerLogic);
        console.log("Proxy:", stakeManagerProxy);
        console.log("");
        console.log("");
        console.log("StateSender");
        console.log("");
        console.log("Logic:", stateSenderLogic);
        console.log("Proxy:", "Does not have a proxy");
        console.log("");
        console.log("");
        console.log("CheckpointManager");
        console.log("");
        console.log("Logic:", checkpointManagerLogic);
        console.log("Proxy:", checkpointManagerProxy);
        console.log("");
        console.log("");
        console.log("ExitHelper");
        console.log("");
        console.log("Logic:", exitHelperLogic);
        console.log("Proxy:", exitHelperProxy);
        console.log("");
        console.log("");
        console.log("CustomSupernetManager");
        console.log("");
        console.log("Logic:", customSupernetManagerLogic);
        console.log("Proxy:", customSupernetManagerProxy);
        console.log("");
        console.log("");
        console.log("RootERC20Predicate");
        console.log("");
        console.log("Logic:", rootERC20PredicateLogic);
        console.log("Proxy:", rootERC20PredicateProxy);
        console.log("");
        console.log("");
        console.log("ChildMintableERC20Predicate");
        console.log("");
        console.log("Logic:", childMintableERC20PredicateLogic);
        console.log("Proxy:", childMintableERC20PredicateProxy);
        console.log("");
        console.log("");
        console.log("RootERC721Predicate");
        console.log("");
        console.log("Logic:", rootERC721PredicateLogic);
        console.log("Proxy:", rootERC721PredicateProxy);
        console.log("");
        console.log("");
        console.log("ChildMintableERC721Predicate");
        console.log("");
        console.log("Logic:", childMintableERC721PredicateLogic);
        console.log("Proxy:", childMintableERC721PredicateProxy);
        console.log("");
        console.log("");
        console.log("RootERC1155Predicate");
        console.log("");
        console.log("Logic:", rootERC1155PredicateLogic);
        console.log("Proxy:", rootERC1155PredicateProxy);
        console.log("");
        console.log("");
        console.log("ChildMintableERC1155Predicate");
        console.log("");
        console.log("Logic:", childMintableERC1155PredicateLogic);
        console.log("Proxy:", childMintableERC1155PredicateProxy);
        console.log("");
        console.log("");
        console.log("See logs for actual addresses.");
    }
}
