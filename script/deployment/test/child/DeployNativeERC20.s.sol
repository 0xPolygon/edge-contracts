// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {NativeERC20} from "contracts/child/NativeERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract NativeERC20Deployer is Script {
    function deployNativeERC20(
        address proxyAdmin,
        address predicate_,
        address rootToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            NativeERC20.initialize,
            (predicate_, rootToken_, name_, symbol_, decimals_, tokenSupply_)
        );

        vm.startBroadcast();

        NativeERC20 nativeERC20 = new NativeERC20();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(nativeERC20), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(nativeERC20);
        proxyAddr = address(proxy);
    }
}

contract DeployNativeERC20 is NativeERC20Deployer {
    function run(
        address proxyAdmin,
        address predicate_,
        address rootToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_
    ) external returns (address logicAddr, address proxyAddr) {
        return deployNativeERC20(proxyAdmin, predicate_, rootToken_, name_, symbol_, decimals_, tokenSupply_);
    }
}
