// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ExitHelper} from "contracts/root/ExitHelper.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ICheckpointManager} from "contracts/interfaces/root/ICheckpointManager.sol";

contract DeployExitHelper is Script {
    function run(
        address proxyAdmin,
        ICheckpointManager checkpointManager
    ) external returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(ExitHelper.initialize, (checkpointManager));

        vm.startBroadcast();

        ExitHelper exitHelper = new ExitHelper();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(exitHelper), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(exitHelper);
        proxyAddr = address(proxy);
    }
}
