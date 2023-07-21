// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {FlowRateDetection} from "contracts/root/flowrate/FlowRateDetection.sol";

contract FlowRateDetectionT is FlowRateDetection {

}

contract UninitializedFlowRateDetectionTest is Test {
    FlowRateDetection flowRateDetection;

    function setUp() public virtual  {
        flowRateDetection = new FlowRateDetectionT();
    }

    function testUninitFlowRateBuckets() public {
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(address(0));
        assertEq(capacity, 0);
        assertEq(depth, 0);
        assertEq(refillTime, 0);
        assertEq(refillRate, 0);
    }
}




