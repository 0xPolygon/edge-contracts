// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC721Predicate} from "contracts/child/RootMintableERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC721PredicateDeployer is Script {
    function deployRootMintableERC721Predicate(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC721Predicate.initialize,
            (newL2StateSender, newStateReceiver, newChildERC721Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        RootMintableERC721Predicate rootMintableERC721Predicate = new RootMintableERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC721Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC721Predicate is RootMintableERC721PredicateDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC721Predicate(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newChildERC721Predicate,
                newChildTokenTemplate
            );
    }
}
