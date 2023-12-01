// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RewardPool} from "contracts/child/validator/RewardPool.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RewardPoolDeployer is Script {
    function deployRewardPool(
        address proxyAdmin,
        address newRewardToken,
        address newRewardWallet,
        address newValidatorSet,
        uint256 newBaseReward
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RewardPool.initialize,
            (newRewardToken, newRewardWallet, newValidatorSet, newBaseReward)
        );

        vm.startBroadcast();

        RewardPool rewardPool = new RewardPool();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(rewardPool), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(rewardPool);
        proxyAddr = address(proxy);
    }
}

contract DeployRewardPool is RewardPoolDeployer {
    function run(
        address proxyAdmin,
        address newRewardToken,
        address newRewardWallet,
        address newValidatorSet,
        uint256 newBaseReward
    ) external returns (address logicAddr, address proxyAddr) {
        return deployRewardPool(proxyAdmin, newRewardToken, newRewardWallet, newValidatorSet, newBaseReward);
    }
}
