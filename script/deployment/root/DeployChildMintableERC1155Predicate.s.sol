// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildMintableERC1155Predicate} from "contracts/root/ChildMintableERC1155Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildMintableERC1155PredicateDeployer is Script {
    function deployChildMintableERC1155Predicate(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newRootERC1155Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildMintableERC1155Predicate.initialize,
            (newStateSender, newExitHelper, newRootERC1155Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        ChildMintableERC1155Predicate childMintableERC1155Predicate = new ChildMintableERC1155Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childMintableERC1155Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childMintableERC1155Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildMintableERC1155Predicate is ChildMintableERC1155PredicateDeployer {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newRootERC1155Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildMintableERC1155Predicate(
                proxyAdmin,
                newStateSender,
                newExitHelper,
                newRootERC1155Predicate,
                newChildTokenTemplate
            );
    }
}
