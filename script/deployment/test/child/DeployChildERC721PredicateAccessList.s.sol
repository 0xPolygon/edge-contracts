// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC721PredicateAccessList} from "contracts/child/ChildERC721PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC721PredicateAccessListDeployer is Script {
    function deployChildERC721PredicateAccessList(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC721PredicateAccessList.initialize,
            (
                newL2StateSender,
                newStateReceiver,
                newRootERC721Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            )
        );

        vm.startBroadcast();

        ChildERC721PredicateAccessList childERC721PredicateAccessList = new ChildERC721PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC721PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC721PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC721PredicateAccessList is ChildERC721PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC721PredicateAccessList(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newRootERC721Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
