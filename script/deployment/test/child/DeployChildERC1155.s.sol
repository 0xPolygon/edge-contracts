// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC1155} from "contracts/child/ChildERC1155.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC1155Deployer is Script {
    function deployChildERC1155(
        address proxyAdmin,
        address rootToken_,
        string memory uri_
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(ChildERC1155.initialize, (rootToken_, uri_));

        vm.startBroadcast();

        ChildERC1155 childERC1155 = new ChildERC1155();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC1155),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC1155);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC1155 is ChildERC1155Deployer {
    function run(
        address proxyAdmin,
        address rootToken_,
        string memory uri_
    ) external returns (address logicAddr, address proxyAddr) {
        return deployChildERC1155(proxyAdmin, rootToken_, uri_);
    }
}
