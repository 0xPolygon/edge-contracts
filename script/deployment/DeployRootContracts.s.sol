// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

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

    address stakeManagerLogic;
    address stakeManagerProxy;
    address stateSenderLogic;
    address stateSenderProxy;
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

        (stakeManagerLogic, stakeManagerProxy) = deployStakeManager(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["StakeManager"].newStakingToken')
        );

        (stateSenderLogic, stateSenderProxy) = deployStateSender();

        (checkpointManagerLogic, checkpointManagerProxy) = deployCheckpointManager(
            config.readAddress('["common"].proxyAdmin'),
            IBLS(config.readAddress('["common"].newBls')),
            IBN256G2(config.readAddress('["CheckpointManager"].newBn256G2')),
            config.readUint('["CheckpointManager"].chainId_'),
            abi.decode(config.readBytes('["CheckpointManager"].newValidatorSet'), (ICheckpointManager.Validator[]))
        );

        (exitHelperLogic, exitHelperProxy) = deployExitHelper(
            config.readAddress('["common"].proxyAdmin'),
            ICheckpointManager(checkpointManagerProxy)
        );

        (customSupernetManagerLogic, customSupernetManagerProxy) = deployCustomSupernetManager(
            config.readAddress('["common"].proxyAdmin'),
            stakeManagerProxy,
            config.readAddress('["common"].newBls'),
            stateSenderProxy,
            config.readAddress('["CustomSupernetManager"].newMatic'),
            config.readAddress('["CustomSupernetManager"].newChildValidatorSet'),
            exitHelperProxy,
            config.readString('["CustomSupernetManager"].newDomain')
        );

        (rootERC20PredicateLogic, rootERC20PredicateProxy) = deployRootERC20Predicate(
            config.readAddress('["common"].proxyAdmin'),
            stateSenderProxy,
            exitHelperProxy,
            config.readAddress('["RootERC20Predicate"].newChildERC20Predicate'),
            config.readAddress('["common"].newChildTokenTemplate'),
            config.readAddress('["RootERC20Predicate"].nativeTokenRootAddress')
        );

        (childMintableERC20PredicateLogic, childMintableERC20PredicateProxy) = deployChildMintableERC20Predicate(
            config.readAddress('["common"].proxyAdmin'),
            stateSenderProxy,
            exitHelperProxy,
            rootERC20PredicateProxy,
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (rootERC721PredicateLogic, rootERC721PredicateProxy) = deployRootERC721Predicate(
            config.readAddress('["common"].proxyAdmin'),
            stateSenderProxy,
            exitHelperProxy,
            config.readAddress('["RootERC721Predicate"].newChildERC721Predicate'),
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (childMintableERC721PredicateLogic, childMintableERC721PredicateProxy) = deployChildMintableERC721Predicate(
            config.readAddress('["common"].proxyAdmin'),
            stateSenderProxy,
            exitHelperProxy,
            rootERC721PredicateProxy,
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (rootERC1155PredicateLogic, rootERC1155PredicateProxy) = deployRootERC1155Predicate(
            config.readAddress('["common"].proxyAdmin'),
            stateSenderProxy,
            exitHelperProxy,
            config.readAddress('["RootERC1155Predicate"].newChildERC1155Predicate'),
            config.readAddress('["common"].newChildTokenTemplate')
        );

        (childMintableERC1155PredicateLogic, childMintableERC1155PredicateProxy) = deployChildMintableERC1155Predicate(
            config.readAddress('["common"].proxyAdmin'),
            stateSenderProxy,
            exitHelperProxy,
            rootERC1155PredicateProxy,
            config.readAddress('["common"].newChildTokenTemplate')
        );

        console.log("Expected addresses:");
        console.log("");
        console.log("StakeManager logic: %s", stakeManagerLogic);
        console.log("StakeManager proxy: %s", stakeManagerProxy);
        console.log("StateSender logic: %s", stateSenderLogic);
        console.log("StateSender proxy: %s", stateSenderProxy);
        console.log("CheckpointManager logic: %s", checkpointManagerLogic);
        console.log("CheckpointManager proxy: %s", checkpointManagerProxy);
        console.log("ExitHelper logic: %s", exitHelperLogic);
        console.log("ExitHelper proxy: %s", exitHelperProxy);
        console.log("CustomSupernetManager logic: %s", customSupernetManagerLogic);
        console.log("CustomSupernetManager proxy: %s", customSupernetManagerProxy);
        console.log("RootERC20Predicate logic: %s", rootERC20PredicateLogic);
        console.log("RootERC20Predicate proxy: %s", rootERC20PredicateProxy);
        console.log("ChildMintableERC20Predicate logic: %s", childMintableERC20PredicateLogic);
        console.log("ChildMintableERC20Predicate proxy: %s", childMintableERC20PredicateProxy);
        console.log("RootERC721Predicate logic: %s", rootERC721PredicateLogic);
        console.log("RootERC721Predicate proxy: %s", rootERC721PredicateProxy);
        console.log("ChildMintableERC721Predicate logic: %s", childMintableERC721PredicateLogic);
        console.log("ChildMintableERC721Predicate proxy: %s", childMintableERC721PredicateProxy);
        console.log("RootERC1155Predicate logic: %s", rootERC1155PredicateLogic);
        console.log("RootERC1155Predicate proxy: %s", rootERC1155PredicateProxy);
        console.log("ChildMintableERC1155Predicate logic: %s", childMintableERC1155PredicateLogic);
        console.log("ChildMintableERC1155Predicate proxy: %s", childMintableERC1155PredicateProxy);
        console.log("");
        console.log("See logs for actual addresses.");
    }
}
