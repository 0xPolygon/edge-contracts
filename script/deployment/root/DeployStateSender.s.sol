// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {StateSender} from "contracts/root/StateSender.sol";

contract DeployStateSender is Script {
    function run() external returns (address contractAddr) {
        vm.broadcast();
        StateSender stateSender = new StateSender();

        contractAddr = address(stateSender);
    }
}
