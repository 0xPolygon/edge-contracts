// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootERC721Predicate} from "contracts/root/RootERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootERC721PredicateDeployer is Script {
    function deployRootERC721Predicate(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootERC721Predicate.initialize,
            (newStateSender, newExitHelper, newChildERC721Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        RootERC721Predicate rootERC721Predicate = new RootERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootERC721Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootERC721Predicate is RootERC721PredicateDeployer {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootERC721Predicate(
                proxyAdmin,
                newStateSender,
                newExitHelper,
                newChildERC721Predicate,
                newChildTokenTemplate
            );
    }
}
