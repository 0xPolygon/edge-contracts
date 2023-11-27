// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/bridge/DeployStateSender.s.sol";
import "script/deployment/bridge/DeployCheckpointManager.s.sol";
import "script/deployment/bridge/DeployExitHelper.s.sol";

contract DeployNewBridgeContractSet is StateSenderDeployer, CheckpointManagerDeployer, ExitHelperDeployer {
    using stdJson for string;

    function run()
        external
        returns (
            address proxyAdmin,
            address stateSender,
            address checkpointManagerLogic,
            address checkpointManagerProxy,
            address exitHelperLogic,
            address exitHelperProxy
        )
    {
        string memory config = vm.readFile("script/deployment/bridgeContractSetConfig.json");

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
    }
}
