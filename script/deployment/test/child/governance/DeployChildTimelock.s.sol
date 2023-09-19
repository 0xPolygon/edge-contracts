// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildTimelock} from "contracts/child/governance/ChildTimelock.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildTimelockDeployer is Script {
    function deployChildTimelock(
        address proxyAdmin,
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(ChildTimelock.initialize, (minDelay, proposers, executors, admin));

        vm.startBroadcast();

        ChildTimelock childTimelock = new ChildTimelock();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childTimelock),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childTimelock);
        proxyAddr = address(proxy);
    }
}

contract DeployChildTimelock is ChildTimelockDeployer {
    function run(
        address proxyAdmin,
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) external returns (address logicAddr, address proxyAddr) {
        return deployChildTimelock(proxyAdmin, minDelay, proposers, executors, admin);
    }
}
