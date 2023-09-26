// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC721} from "contracts/child/ChildERC721.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC721Deployer is Script {
    function deployChildERC721(
        address proxyAdmin,
        address rootToken_,
        string memory name_,
        string memory symbol_
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(ChildERC721.initialize, (rootToken_, name_, symbol_));

        vm.startBroadcast();

        ChildERC721 childERC721 = new ChildERC721();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(childERC721), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(childERC721);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC721 is ChildERC721Deployer {
    function run(
        address proxyAdmin,
        address rootToken_,
        string memory name_,
        string memory symbol_
    ) external returns (address logicAddr, address proxyAddr) {
        return deployChildERC721(proxyAdmin, rootToken_, name_, symbol_);
    }
}
