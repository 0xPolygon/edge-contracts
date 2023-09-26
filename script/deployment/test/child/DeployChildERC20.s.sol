// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC20Deployer is Script {
    function deployChildERC20(
        address proxyAdmin,
        address rootToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(ChildERC20.initialize, (rootToken_, name_, symbol_, decimals_));

        vm.startBroadcast();

        ChildERC20 childERC20 = new ChildERC20();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(childERC20), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(childERC20);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC20 is ChildERC20Deployer {
    function run(
        address proxyAdmin,
        address rootToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external returns (address logicAddr, address proxyAddr) {
        return deployChildERC20(proxyAdmin, rootToken_, name_, symbol_, decimals_);
    }
}
