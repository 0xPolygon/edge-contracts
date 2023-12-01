// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC1155PredicateAccessList} from "contracts/child/RootMintableERC1155PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC1155PredicateAccessListDeployer is Script {
    function deployRootMintableERC1155PredicateAccessList(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC1155PredicateAccessList.initialize,
            (
                newL2StateSender,
                newStateReceiver,
                newChildERC1155Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            )
        );

        vm.startBroadcast();

        RootMintableERC1155PredicateAccessList rootMintableERC1155PredicateAccessList = new RootMintableERC1155PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC1155PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC1155PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC1155PredicateAccessList is RootMintableERC1155PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC1155PredicateAccessList(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newChildERC1155Predicate,
                newChildTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
