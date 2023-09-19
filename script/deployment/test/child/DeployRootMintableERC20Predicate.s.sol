// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC20Predicate} from "contracts/child/RootMintableERC20Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC20PredicateDeployer is Script {
    function deployRootMintableERC20Predicate(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC20Predicate.initialize,
            (newL2StateSender, newStateReceiver, newChildERC20Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        RootMintableERC20Predicate rootMintableERC20Predicate = new RootMintableERC20Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC20Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC20Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC20Predicate is RootMintableERC20PredicateDeployer {
    function run(
        address proxyAdmin,
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC20Predicate(
                proxyAdmin,
                newL2StateSender,
                newStateReceiver,
                newChildERC20Predicate,
                newChildTokenTemplate
            );
    }
}
