// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildMintableERC20Predicate} from "contracts/root/ChildMintableERC20Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployChildMintableERC20Predicate is Script {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newRootERC20Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildMintableERC20Predicate.initialize,
            (newStateSender, newExitHelper, newRootERC20Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        ChildMintableERC20Predicate childMintableERC20Predicate = new ChildMintableERC20Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childMintableERC20Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childMintableERC20Predicate);
        proxyAddr = address(proxy);
    }
}
