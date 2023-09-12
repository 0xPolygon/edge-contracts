// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootERC1155Predicate} from "contracts/root/RootERC1155Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootERC1155PredicateDeployer is Script {
    function deployRootERC1155Predicate(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC1155Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootERC1155Predicate.initialize,
            (newStateSender, newExitHelper, newChildERC1155Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        RootERC1155Predicate rootERC1155Predicate = new RootERC1155Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootERC1155Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootERC1155Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootERC1155Predicate is RootERC1155PredicateDeployer {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC1155Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootERC1155Predicate(
                proxyAdmin,
                newStateSender,
                newExitHelper,
                newChildERC1155Predicate,
                newChildTokenTemplate
            );
    }
}
