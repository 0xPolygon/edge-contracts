// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ValidatorSet, ValidatorInit} from "contracts/child/validator/ValidatorSet.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ValidatorSetDeployer is Script {
    function deployValidatorSet(
        address proxyAdmin,
        address newStateSender,
        address newStateReceiver,
        address newRootChainManager,
        uint256 newEpochSize,
        ValidatorInit[] memory initialValidators
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ValidatorSet.initialize,
            (newStateSender, newStateReceiver, newRootChainManager, newEpochSize, initialValidators)
        );

        vm.startBroadcast();

        ValidatorSet validatorSet = new ValidatorSet();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(validatorSet),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(validatorSet);
        proxyAddr = address(proxy);
    }
}

contract DeployValidatorSet is ValidatorSetDeployer {
    function run(
        address proxyAdmin,
        address newStateSender,
        address newStateReceiver,
        address newRootChainManager,
        uint256 newEpochSize,
        ValidatorInit[] memory initialValidators
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployValidatorSet(
                proxyAdmin,
                newStateSender,
                newStateReceiver,
                newRootChainManager,
                newEpochSize,
                initialValidators
            );
    }
}
