// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/root/DeployStateSender.s.sol";
import "script/deployment/root/DeployCheckpointManager.s.sol";
import "script/deployment/root/DeployExitHelper.s.sol";
import "script/deployment/root/staking/DeployCustomSupernetManager.s.sol";

contract DeployNewRootContractSet is
    StateSenderDeployer,
    CheckpointManagerDeployer,
    ExitHelperDeployer,
    CustomSupernetManagerDeployer
{
    using stdJson for string;

    function run()
        external
        returns (
            address proxyAdmin,
            address stateSender,
            address checkpointManagerLogic,
            address checkpointManagerProxy,
            address exitHelperLogic,
            address exitHelperProxy,
            address customSupernetManagerLogic,
            address customSupernetManagerProxy
        )
    {
        string memory config = vm.readFile("script/deployment/rootContractSetConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        stateSender = deployStateSender();

        // To be initialized manually later.
        (checkpointManagerLogic, checkpointManagerProxy) = deployCheckpointManager(
            proxyAdmin,
            config.readAddress('["CheckpointManager"].INITIALIZER')
        );

        (exitHelperLogic, exitHelperProxy) = deployExitHelper(proxyAdmin, ICheckpointManager(checkpointManagerProxy));

        (customSupernetManagerLogic, customSupernetManagerProxy) = deployCustomSupernetManager(
            proxyAdmin,
            config.readAddress('["CustomSupernetManager"].newStakeManager'),
            config.readAddress('["CustomSupernetManager"].newBls'),
            stateSender,
            config.readAddress('["CustomSupernetManager"].newMatic'),
            config.readAddress('["CustomSupernetManager"].newChildValidatorSet'),
            exitHelperProxy,
            config.readString('["CustomSupernetManager"].newDomain')
        );
    }
}
