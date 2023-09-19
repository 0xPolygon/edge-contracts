// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ForkParams} from "contracts/child/ForkParams.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ForkParamsDeployer is Script {
    function deployForkParams(
        address proxyAdmin,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(ForkParams.initialize, (newOwner));

        vm.startBroadcast();

        ForkParams forkParams = new ForkParams();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(forkParams), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(forkParams);
        proxyAddr = address(proxy);
    }
}

contract DeployForkParams is ForkParamsDeployer {
    function run(address proxyAdmin, address newOwner) external returns (address logicAddr, address proxyAddr) {
        return deployForkParams(proxyAdmin, newOwner);
    }
}
