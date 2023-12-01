// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {StateReceiver} from "contracts/child/StateReceiver.sol";

abstract contract StateReceiverDeployer is Script {
    function deployStateReceiver() internal returns (address contractAddr) {
        vm.startBroadcast();

        StateReceiver stateReceiver = new StateReceiver();

        vm.stopBroadcast();

        contractAddr = address(stateReceiver);
    }
}

contract DeployStateReceiver is StateReceiverDeployer {
    function run() external returns (address contractAddr) {
        return deployStateReceiver();
    }
}
