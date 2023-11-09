// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC1155Predicate} from "contracts/child/ChildERC1155Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC1155PredicateDeployer is Script {
    function deployChildERC1155Predicate(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC1155Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC1155Predicate.initialize,
            (newL2StateSender, newStateReceiver, newRootERC1155Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        ChildERC1155Predicate childERC1155Predicate = new ChildERC1155Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC1155Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC1155Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC1155Predicate is ChildERC1155PredicateDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC1155Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC1155Predicate(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newRootERC1155Predicate,
                newChildTokenTemplate
            );
    }
}
