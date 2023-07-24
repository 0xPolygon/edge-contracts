// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {FlowRateDetection} from "contracts/root/flowrate/FlowRateDetection.sol";

contract FlowRateDetectionT is FlowRateDetection {
    function activateWithdrawalQueue() external {
        _activateWithdrawalQueue();
    }
    function deactivateWithdrawalQueue() external {
        _deactivateWithdrawalQueue();
    }
    function setFlowRateThreshold(address token, uint256 capacity, uint256 refillRate) external {
        _setFlowRateThreshold(token, capacity, refillRate);
    }
    function updateFlowRateBucket(address token, uint256 amount) external returns (bool delayWithdrawal) {
        return _updateFlowRateBucket(token, amount);
    
    }
    
}


abstract contract FlowRateDetectionTests is Test {
    FlowRateDetectionT flowRateDetection;

    function setUp() public virtual  {
        flowRateDetection = new FlowRateDetectionT();
    }
}


contract UninitializedFlowRateDetectionTest is FlowRateDetectionTests {
    function testUninitFlowRateBuckets() public {
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(address(0));
        assertEq(capacity, 0);
        assertEq(depth, 0);
        assertEq(refillTime, 0);
        assertEq(refillRate, 0);
    }

    function testUnWithdrawalQueueActivated() public {
        bool withdrawalQueueActivated = flowRateDetection.withdrawalQueueActivated();
        assertEq(withdrawalQueueActivated, false);
    }
}


contract ControlFlowRateDetectionTest is FlowRateDetectionTests {
    function testActivateWithdrawalQueue() public {
        flowRateDetection.activateWithdrawalQueue();

        bool withdrawalQueueActivated = flowRateDetection.withdrawalQueueActivated();
        assertEq(withdrawalQueueActivated, true);
    }

    function testDeactivateWithdrawalQueue() public {
        flowRateDetection.activateWithdrawalQueue();
        flowRateDetection.deactivateWithdrawalQueue();

        bool withdrawalQueueActivated = flowRateDetection.withdrawalQueueActivated();
        assertEq(withdrawalQueueActivated, false);
    }

    function testSetFlowRateThreshold() public {
        flowRateDetection.setFlowRateThreshold(address(1000), 100, 10);
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(address(1000));
        assertEq(capacity, 100);
        assertEq(depth, 0);
        assertEq(refillTime, 0);
        assertEq(refillRate, 10);
    }

    function testSetFlowRateThresholdBadToken() public {
        vm.expectRevert();
        flowRateDetection.setFlowRateThreshold(address(0), 100, 10);
    }

    function testSetFlowRateThresholdBadCapacity() public {
        vm.expectRevert();
        flowRateDetection.setFlowRateThreshold(address(1000), 0, 10);
    }
    function testSetFlowRateThresholdBadFillRate() public {
        vm.expectRevert();
        flowRateDetection.setFlowRateThreshold(address(1000), 100, 0);
    }
}

contract OperationalFlowRateDetectionTest is FlowRateDetectionTests {

    function setUp() public override  {
        super.setUp();
        // Set for 1,000,000 of a token per hour, where the token has 18 decimals.
        flowRateDetection.setFlowRateThreshold(address(1000), 1000000000000000000000000, 277777777777777777777);
    }

    // function testUpdateFlowRateBucketSingle() public {
    //     flowRateDetection._updateFlowRateBucket
    //     vm.expectRevert();
    //     // Set for 1,000,000 of a token per hour, where the token has 18 decimals.
    //     flowRateDetection.setFlowRateThreshold(address(1000), 1000000000000000000000000, 277777777777777777777);


    // }
}



