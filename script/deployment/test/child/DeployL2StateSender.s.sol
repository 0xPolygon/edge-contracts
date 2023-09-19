// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {L2StateSender} from "contracts/child/L2StateSender.sol";

abstract contract L2StateSenderDeployer is Script {
    function deployL2StateSender() internal returns (address contractAddr) {
        vm.startBroadcast();

        L2StateSender l2StateSender = new L2StateSender();

        vm.stopBroadcast();

        contractAddr = address(l2StateSender);
    }
}

contract DeployL2StateSender is L2StateSenderDeployer {
    function run() external returns (address contractAddr) {
        return deployL2StateSender();
    }
}
