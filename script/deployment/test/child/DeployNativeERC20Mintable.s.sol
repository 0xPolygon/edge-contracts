// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {NativeERC20Mintable} from "contracts/child/NativeERC20Mintable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract NativeERC20MintableDeployer is Script {
    function deployNativeERC20Mintable(
        address proxyAdmin,
        address predicate_,
        address owner_,
        address rootToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            NativeERC20Mintable.initialize,
            (predicate_, owner_, rootToken_, name_, symbol_, decimals_, tokenSupply_)
        );

        vm.startBroadcast();

        NativeERC20Mintable nativeERC20Mintable = new NativeERC20Mintable();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(nativeERC20Mintable),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(nativeERC20Mintable);
        proxyAddr = address(proxy);
    }
}

contract DeployNativeERC20Mintable is NativeERC20MintableDeployer {
    function run(
        address proxyAdmin,
        address predicate_,
        address owner_,
        address rootToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployNativeERC20Mintable(
                proxyAdmin,
                predicate_,
                owner_,
                rootToken_,
                name_,
                symbol_,
                decimals_,
                tokenSupply_
            );
    }
}
