// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {System} from "contracts/child/System.sol";

abstract contract SystemDeployer is Script {
    function deploySystem() internal returns (address contractAddr) {
        vm.startBroadcast();

        System system = new System();

        vm.stopBroadcast();

        contractAddr = address(system);
    }
}

contract DeploySystem is SystemDeployer {
    function run() external returns (address contractAddr) {
        return deploySystem();
    }
}
