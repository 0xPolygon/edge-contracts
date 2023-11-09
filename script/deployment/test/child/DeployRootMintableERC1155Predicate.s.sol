// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC1155Predicate} from "contracts/child/RootMintableERC1155Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC1155PredicateDeployer is Script {
    function deployRootMintableERC1155Predicate(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC1155Predicate.initialize,
            (newL2StateSender, newStateReceiver, newChildERC1155Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        RootMintableERC1155Predicate rootMintableERC1155Predicate = new RootMintableERC1155Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC1155Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC1155Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC1155Predicate is RootMintableERC1155PredicateDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC1155Predicate(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newChildERC1155Predicate,
                newChildTokenTemplate
            );
    }
}
