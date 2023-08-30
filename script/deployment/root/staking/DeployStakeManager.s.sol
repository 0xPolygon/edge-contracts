// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {StakeManager} from "contracts/root/staking/StakeManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployStakeManager is Script {
    function run(address proxyAdmin, address newStakingToken) external returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(StakeManager.initialize, (newStakingToken));

        vm.startBroadcast();

        StakeManager stakeManager = new StakeManager();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(stakeManager),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(stakeManager);
        proxyAddr = address(proxy);
    }
}
