// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC1155PredicateAccessList} from "contracts/child/ChildERC1155PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC1155PredicateAccessListDeployer is Script {
    function deployChildERC1155PredicateAccessList(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC1155Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC1155PredicateAccessList.initialize,
            (
                newL2StateSender,
                newStateReceiver,
                newRootERC1155Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            )
        );

        vm.startBroadcast();

        ChildERC1155PredicateAccessList childERC1155PredicateAccessList = new ChildERC1155PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC1155PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC1155PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC1155PredicateAccessList is ChildERC1155PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC1155Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC1155PredicateAccessList(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newRootERC1155Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
