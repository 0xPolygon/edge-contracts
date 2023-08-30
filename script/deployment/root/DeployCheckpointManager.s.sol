// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IBLS} from "contracts/interfaces/common/IBLS.sol";
import {IBN256G2} from "contracts/interfaces/common/IBN256G2.sol";
import {ICheckpointManager} from "contracts/interfaces/root/ICheckpointManager.sol";

contract DeployCheckpointManager is Script {
    function run(
        address proxyAdmin,
        IBLS newBls,
        IBN256G2 newBn256G2,
        uint256 chainId_,
        ICheckpointManager.Validator[] calldata newValidatorSet
    ) external returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            CheckpointManager.initialize,
            (newBls, newBn256G2, chainId_, newValidatorSet)
        );

        vm.startBroadcast();

        CheckpointManager checkpointManager = new CheckpointManager();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(checkpointManager),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(checkpointManager);
        proxyAddr = address(proxy);
    }
}
