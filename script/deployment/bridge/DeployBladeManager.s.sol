// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {GenesisAccount} from "contracts/lib/GenesisLib.sol";
import {BladeManager} from "contracts/bridge/BladeManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract BladeManagerDeployer is Script {
    function deployBladeManager(
        address proxyAdmin,
        address newRootERC20Predicate,
        GenesisAccount[] calldata genesisValidators
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(BladeManager.initialize, (newRootERC20Predicate, genesisValidators));

        vm.startBroadcast();

        BladeManager bladeManager = new BladeManager();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(bladeManager),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(bladeManager);
        proxyAddr = address(proxy);
    }
}

contract DeployBladeManager is BladeManagerDeployer {
    function run(
        address proxyAdmin,
        address newRootERC20Predicate,
        GenesisAccount[] calldata genesisValidators
    ) external returns (address logicAddr, address proxyAddr) {
        return deployBladeManager(proxyAdmin, newRootERC20Predicate, genesisValidators);
    }
}
