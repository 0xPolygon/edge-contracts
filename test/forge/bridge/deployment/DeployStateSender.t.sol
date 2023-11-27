// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployStateSender} from "script/deployment/bridge/DeployStateSender.s.sol";

import {StateSender} from "contracts/bridge/StateSender.sol";

contract DeployStateSenderTest is Test {
    DeployStateSender private deployer;

    StateSender internal stateSender;

    function setUp() public {
        deployer = new DeployStateSender();

        address contractAddr = deployer.run();
        stateSender = StateSender(contractAddr);
    }

    function testRun() public {
        assertEq(stateSender.counter(), 0);
    }
}
