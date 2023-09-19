// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC20PredicateAccessList} from "contracts/child/RootMintableERC20PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC20PredicateAccessListDeployer is Script {
    function deployRootMintableERC20PredicateAccessList(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC20PredicateAccessList.initialize,
            (
                newL2StateSender,
                newStateReceiver,
                newChildERC20Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            )
        );

        vm.startBroadcast();

        RootMintableERC20PredicateAccessList rootMintableERC20PredicateAccessList = new RootMintableERC20PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC20PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC20PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC20PredicateAccessList is RootMintableERC20PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC20PredicateAccessList(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newChildERC20Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
