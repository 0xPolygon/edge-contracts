// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {StateSender} from "contracts/root/StateSender.sol";

abstract contract StateSenderDeployer is Script {
    function deployStateSender() internal returns (address proxyAddr, address logicAddr) {
        vm.broadcast();
        StateSender stateSender = new StateSender();

        logicAddr = address(stateSender);
        proxyAddr;
    }
}

contract DeployStateSender is StateSenderDeployer {
    function run() external returns (address proxyAddr, address logicAddr) {
        return deployStateSender();
    }
}
