// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC721Predicate} from "contracts/child/ChildERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC721PredicateDeployer is Script {
    function deployChildERC721Predicate(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC721Predicate.initialize,
            (newL2StateSender, newStateReceiver, newRootERC721Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        ChildERC721Predicate childERC721Predicate = new ChildERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC721Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC721Predicate is ChildERC721PredicateDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC721Predicate(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newRootERC721Predicate,
                newChildTokenTemplate
            );
    }
}
