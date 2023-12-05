// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {EpochManager} from "contracts/blade/validator/EpochManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract EpochManagerDeployer is Script {
    function deployEpochManager(
        address proxyAdmin,
        address newStakeManager,
        address newRewardToken,
        address newRewardWallet,
        address newNetworkParams
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            EpochManager.initialize,
            (newStakeManager, newRewardToken, newRewardWallet, newNetworkParams)
        );

        vm.startBroadcast();

        EpochManager epochManager = new EpochManager();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(epochManager),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(epochManager);
        proxyAddr = address(proxy);
    }
}

contract DeployEpochManager is EpochManagerDeployer {
    function run(
        address proxyAdmin,
        address newStakeManager,
        address newRewardToken,
        address newRewardWallet,
        address newNetworkParams
    ) external returns (address logicAddr, address proxyAddr) {
        return deployEpochManager(proxyAdmin, newStakeManager, newRewardToken, newRewardWallet, newNetworkParams);
    }
}
