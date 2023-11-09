// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC20PredicateAccessList} from "contracts/child/ChildERC20PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC20PredicateAccessListDeployer is Script {
    function deployChildERC20PredicateAccessList(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC20PredicateAccessList.initialize,
            (
                newL2StateSender,
                newStateReceiver,
                newRootERC20Predicate,
                newChildTokenTemplate,
                newNativeTokenRootAddress,
                newUseAllowList,
                newUseBlockList,
                newOwner
            )
        );

        vm.startBroadcast();

        ChildERC20PredicateAccessList childERC20PredicateAccessList = new ChildERC20PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC20PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC20PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC20PredicateAccessList is ChildERC20PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC20PredicateAccessList(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newRootERC20Predicate,
                newChildTokenTemplate,
                newNativeTokenRootAddress,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
