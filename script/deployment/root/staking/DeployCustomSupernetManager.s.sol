// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {CustomSupernetManager} from "contracts/root/staking/CustomSupernetManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract CustomSupernetManagerDeployer is Script {
    function deployCustomSupernetManager(
        address proxyAdmin,
        address newStakeManager,
        address newBls,
        address newStateSender,
        address newMatic,
        address newChildValidatorSet,
        address newExitHelper,
        string memory newDomain
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            CustomSupernetManager.initialize,
            (newStakeManager, newBls, newStateSender, newMatic, newChildValidatorSet, newExitHelper, newDomain)
        );

        vm.startBroadcast();

        CustomSupernetManager customSupernetManager = new CustomSupernetManager();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(customSupernetManager),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(customSupernetManager);
        proxyAddr = address(proxy);
    }
}

contract DeployCustomSupernetManager is CustomSupernetManagerDeployer {
    function run(
        address proxyAdmin,
        address newStakeManager,
        address newBls,
        address newStateSender,
        address newMatic,
        address newChildValidatorSet,
        address newExitHelper,
        string memory newDomain
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployCustomSupernetManager(
                proxyAdmin,
                newStakeManager,
                newBls,
                newStateSender,
                newMatic,
                newChildValidatorSet,
                newExitHelper,
                newDomain
            );
    }
}
