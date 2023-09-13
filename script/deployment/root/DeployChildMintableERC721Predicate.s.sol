// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildMintableERC721Predicate} from "contracts/root/ChildMintableERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildMintableERC721PredicateDeployer is Script {
    function deployChildMintableERC721Predicate(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildMintableERC721Predicate.initialize,
            (newStateSender, newExitHelper, newRootERC721Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        ChildMintableERC721Predicate childMintableERC721Predicate = new ChildMintableERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childMintableERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childMintableERC721Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildMintableERC721Predicate is ChildMintableERC721PredicateDeployer {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildMintableERC721Predicate(
                proxyAdmin,
                newStateSender,
                newExitHelper,
                newRootERC721Predicate,
                newChildTokenTemplate
            );
    }
}
