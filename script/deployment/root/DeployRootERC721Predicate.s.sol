// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootERC721Predicate} from "contracts/root/RootERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployRootERC721Predicate is Script {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootERC721Predicate.initialize,
            (newStateSender, newExitHelper, newChildERC721Predicate, newChildTokenTemplate)
        );

        vm.startBroadcast();

        RootERC721Predicate rootERC721Predicate = new RootERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootERC721Predicate);
        proxyAddr = address(proxy);
    }
}
