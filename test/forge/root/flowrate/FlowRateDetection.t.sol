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

    address public TOKEN = address(1000);
    uint256 public CAPACITY = 10000;
    uint256 public REFILL_RATE = 50;

    function setUp() public virtual  {
        flowRateDetection = new FlowRateDetectionT();
    }
}


contract UninitializedFlowRateDetectionTest is FlowRateDetectionTests {
    function testUninitFlowRateBuckets() public {
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);
        assertEq(capacity, 0, "Capacity");
        assertEq(depth, 0, "Depth");
        assertEq(refillTime, 0, "Refill time");
        assertEq(refillRate, 0, "Refill rate");
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
        flowRateDetection.setFlowRateThreshold(TOKEN, CAPACITY, REFILL_RATE);
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, 0, "Depth");
        assertEq(refillTime, 0, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");
    }

    function testSetFlowRateThresholdBadToken() public {
        vm.expectRevert();
        flowRateDetection.setFlowRateThreshold(address(0), CAPACITY, REFILL_RATE);
    }

    function testSetFlowRateThresholdBadCapacity() public {
        vm.expectRevert();
        flowRateDetection.setFlowRateThreshold(TOKEN, 0, REFILL_RATE);
    }
    function testSetFlowRateThresholdBadFillRate() public {
        vm.expectRevert();
        flowRateDetection.setFlowRateThreshold(TOKEN, CAPACITY, 0);
    }
}

contract OperationalFlowRateDetectionTest is FlowRateDetectionTests {
    event WithdrawalForNonFlowRatedToken(address indexed token, uint256 amount);

    function setUp() public override  {
        super.setUp();
        flowRateDetection.setFlowRateThreshold(TOKEN, CAPACITY, REFILL_RATE);
    }

    function testUpdateFlowRateBucketSingle() public {
        uint256 numTokens = 2000;
        uint256 now1 = 150000;
        vm.warp(now1);
        bool notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens);
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, CAPACITY - numTokens, "Depth");
        assertEq(refillTime, now1, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");
        assertEq(notConfigured, false, "Not configured");

        bool withdrawalQueueActivated = flowRateDetection.withdrawalQueueActivated();
        assertEq(withdrawalQueueActivated, false);
    }

    function testUpdateFlowRateBucketMultiple() public {
        uint256 numTokens1 = 2000;
        uint256 now1 = 150000;
        vm.warp(now1);
        bool notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens1);
        assertEq(notConfigured, false, "Not configured");

        uint256 numTokens2 = 3000;
        uint256 now2 = 150010;
        vm.warp(now2);
        notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens2);
        assertEq(notConfigured, false, "Not configured");
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);

        uint256 calcDepth = CAPACITY - numTokens1 + REFILL_RATE * (now2 - now1);
        if (calcDepth > CAPACITY) { calcDepth = CAPACITY; }
        calcDepth -= numTokens2;
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, calcDepth, "Depth");
        assertEq(refillTime, now2, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");

        uint256 numTokens3 = 100;
        uint256 now3 = 150020;
        vm.warp(now3);
        notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens3);
        assertEq(notConfigured, false, "Not configured");
        (capacity, depth, refillTime, refillRate) = flowRateDetection.flowRateBuckets(TOKEN);
        calcDepth = calcDepth + REFILL_RATE * (now3 - now2);
        if (calcDepth > CAPACITY) { calcDepth = CAPACITY; }
        calcDepth -= numTokens3;
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, calcDepth, "Depth");
        assertEq(refillTime, now3, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");
    }

    function testUpdateFlowRateBucketOverflow() public {
        uint256 numTokens1 = 2000;
        uint256 now1 = 150000;
        vm.warp(now1);
        bool notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens1);
        assertEq(notConfigured, false, "Not configured");

        // Have a large elapsed time, so the bucket will overflow.
        uint256 numTokens2 = 3000;
        uint256 now2 = 200000;
        vm.warp(now2);
        notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens2);
        assertEq(notConfigured, false, "Not configured");
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);

        uint256 calcDepth = CAPACITY - numTokens2;
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, calcDepth, "Depth");
        assertEq(refillTime, now2, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");
    }

    function testUpdateFlowRateBucketJustEmpty() public {
        updateFlowRateBucketEmptyTest(CAPACITY);
    }

    function testUpdateFlowRateBucketEmpty() public {
        updateFlowRateBucketEmptyTest(CAPACITY + 1);
    }

    function updateFlowRateBucketEmptyTest(uint256 numTokens) private {
        uint256 numTokens1 = numTokens;
        uint256 now1 = 150000;
        vm.warp(now1);
        bool notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens1);
        assertEq(notConfigured, false, "Not configured");
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, 0, "Depth");
        assertEq(refillTime, now1, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");

        bool withdrawalQueueActivated = flowRateDetection.withdrawalQueueActivated();
        assertEq(withdrawalQueueActivated, true);
    }

    function testUpdateFlowRateBucketAfterEmpty() public {
        uint256 numTokens1 = CAPACITY;
        uint256 now1 = 150000;
        vm.warp(now1);
        bool notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens1);
        assertEq(notConfigured, false, "Not configured");

        // Have a large elapsed time, so the bucket will overflow.
        uint256 numTokens2 = 3000;
        uint256 now2 = 150100;
        vm.warp(now2);
        notConfigured = flowRateDetection.updateFlowRateBucket(TOKEN, numTokens2);
        assertEq(notConfigured, false, "Not configured");
        ( uint256 capacity, uint256 depth, uint256 refillTime, uint256 refillRate) 
             = flowRateDetection.flowRateBuckets(TOKEN);

        uint256 calcDepth = REFILL_RATE * (now2 - now1) - numTokens2;
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(depth, calcDepth, "Depth");
        assertEq(refillTime, now2, "Refill time");
        assertEq(refillRate, REFILL_RATE, "Refill rate");

        bool withdrawalQueueActivated = flowRateDetection.withdrawalQueueActivated();
        assertEq(withdrawalQueueActivated, true);
    }

    function testUpdateFlowRateBucketUnconfigured() public {
        address unconfiguredToken = address(101);
        uint256 numTokens1 = 100;
        uint256 now1 = 150000;
        vm.warp(now1);
        vm.expectEmit(true, false, false, true);
        emit WithdrawalForNonFlowRatedToken(unconfiguredToken, numTokens1);
        bool notConfigured = flowRateDetection.updateFlowRateBucket(unconfiguredToken, numTokens1);
        assertEq(notConfigured, true, "Not configured");
    }
}



