// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {FlowRateWithdrawalQueue} from "contracts/root/flowrate/FlowRateWithdrawalQueue.sol";

contract FlowRateWithdrawalQueueT is FlowRateWithdrawalQueue {  
    uint256 public constant DEFAULT_WITHDRAW_DELAY = 60 * 60 * 24;



    function init() external {
        __FlowRateWithdrawalQueue_init();
    }
    function setWithdrawalDelay(uint256 delay) external {
        _setWithdrawalDelay(delay);
    }
    function enqueueWithdrawal(address receiver, address withdrawer, address token, uint256 amount) external {
        _enqueueWithdrawal(receiver, withdrawer, token, amount);
    }
    function dequeueWithdrawal(
        address receiver
    ) external returns (bool more, address withdrawer, address token, uint256 amount) {
        return _dequeueWithdrawal(receiver);
    }

}


abstract contract FlowRateWithdrawalQueueTests is Test {
    FlowRateWithdrawalQueueT flowRateWithdrawalQueue;

    function setUp() public virtual  {
        flowRateWithdrawalQueue = new FlowRateWithdrawalQueueT();
    }
}


contract UninitializedFlowRateWithdrawalQueueTests is FlowRateWithdrawalQueueTests {
    address constant USER = address(125);

    function testUninitWithdrawalQueue() public {
        uint256 delay = flowRateWithdrawalQueue.withdrawalDelay();
        assertEq(delay, 0, "Delay");
    }

    function testUninitPendingWithdrawals() public {
        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = flowRateWithdrawalQueue.getPendingWithdrawals(USER);
        assertEq(pending.length, 0, "Pending withdrawal length");
    }

    function testDequeueEmpty() public {
        (bool more, address withdrawer, address token, uint256 amount) = flowRateWithdrawalQueue.dequeueWithdrawal(USER);
        assertEq(more, false, "More");
        assertEq(withdrawer, address(0), "Withdrawer");
        assertEq(token, address(0), "Token");
        assertEq(amount, 0, "Amount");
    }
}

contract ControlFlowRateWithdrawalQueueTests is FlowRateWithdrawalQueueTests {
    event WithdrawalDelayUpdated(uint256 delay);

    function testInitWithdrawalQueue() public {
        uint256 expectedDelay = flowRateWithdrawalQueue.DEFAULT_WITHDRAW_DELAY();
        vm.expectEmit(false, false, false, true);
        emit WithdrawalDelayUpdated(expectedDelay);
        flowRateWithdrawalQueue.init();
        uint256 delay = flowRateWithdrawalQueue.withdrawalDelay();
        assertEq(delay, expectedDelay, "Delay");
    }

    function testSetWithdrawalDelay() public {
        uint256 expectedDelay = 1999;
        flowRateWithdrawalQueue.init();
        vm.expectEmit(false, false, false, true);
        emit WithdrawalDelayUpdated(expectedDelay);
        flowRateWithdrawalQueue.setWithdrawalDelay(expectedDelay);
        uint256 delay = flowRateWithdrawalQueue.withdrawalDelay();
        assertEq(delay, expectedDelay, "Delay");
    }
}

contract OperationalFlowRateWithdrawalQueueTests is FlowRateWithdrawalQueueTests {
    address constant RUSER1 = address(12345);
    address constant RUSER2 = address(12346);
    address constant WUSER1 = address(12223345);
    address constant WUSER2 = address(11112346);

    address constant TOKEN1 = address(1000012);
    address constant TOKEN2 = address(100123);

    uint256 public withdrawalDelay;

    function setUp() public override {
        super.setUp();
        flowRateWithdrawalQueue.init();

        withdrawalDelay = flowRateWithdrawalQueue.withdrawalDelay();
    }

    function testEnqueueWithdrawal() public {
        uint256 now1 = 100;
        vm.warp(now1);
        uint256 amount = 123;
        flowRateWithdrawalQueue.enqueueWithdrawal(RUSER1, WUSER1, TOKEN1, amount);

        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = flowRateWithdrawalQueue.getPendingWithdrawals(RUSER1);
        assertEq(pending.length, 1, "Pending withdrawal length");
        assertEq(pending[0].withdrawer, WUSER1, "Withdrawer");
        assertEq(pending[0].token, TOKEN1, "Token");
        assertEq(pending[0].amount, amount, "Amount");
        assertEq(pending[0].timestamp, now1, "Timestamp");
    }

    function testEnqueueTwoWithdrawals() public {
        uint256 now1 = 100;
        vm.warp(now1);
        uint256 amount1 = 123;
        uint256 amount2 = 456;
        flowRateWithdrawalQueue.enqueueWithdrawal(RUSER1, WUSER1, TOKEN1, amount1);
        uint256 now2 = 200;
        vm.warp(now2);
        flowRateWithdrawalQueue.enqueueWithdrawal(RUSER1, WUSER2, TOKEN2, amount2);

        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = flowRateWithdrawalQueue.getPendingWithdrawals(RUSER1);
        assertEq(pending.length, 2, "Pending withdrawal length");
        assertEq(pending[0].withdrawer, WUSER1, "Withdrawer");
        assertEq(pending[0].token, TOKEN1, "Token");
        assertEq(pending[0].amount, amount1, "Amount");
        assertEq(pending[0].timestamp, now1, "Timestamp");
        assertEq(pending[1].withdrawer, WUSER2, "Withdrawer");
        assertEq(pending[1].token, TOKEN2, "Token");
        assertEq(pending[1].amount, amount2, "Amount");
        assertEq(pending[1].timestamp, now2, "Timestamp");
    }

    function testDequeueSingle() public {
        uint256 now1 = 100;
        vm.warp(now1);
        uint256 amount1 = 123;
        flowRateWithdrawalQueue.enqueueWithdrawal(RUSER1, WUSER1, TOKEN1, amount1);

        uint256 now2 = now1 + withdrawalDelay;
        vm.warp(now2);

        (bool more, address withdrawer, address token, uint256 amount) = flowRateWithdrawalQueue.dequeueWithdrawal(RUSER1);
        assertEq(more, false, "More");
        assertEq(withdrawer, WUSER1, "Withdrawer");
        assertEq(token, TOKEN1, "Token");
        assertEq(amount, amount1, "Amount");
    }


    function testDequeueDouble() public {
        uint256 now1 = 100;
        vm.warp(now1);
        uint256 amount1 = 123;
        flowRateWithdrawalQueue.enqueueWithdrawal(RUSER1, WUSER1, TOKEN1, amount1);
        uint256 now2 = 200;
        vm.warp(now2);
        uint256 amount2 = 456;
        flowRateWithdrawalQueue.enqueueWithdrawal(RUSER1, WUSER2, TOKEN2, amount2);

        uint256 now3 = now2 + withdrawalDelay;
        vm.warp(now3);

        (bool more, address withdrawer, address token, uint256 amount) = flowRateWithdrawalQueue.dequeueWithdrawal(RUSER1);
        assertEq(more, true, "More");
        assertEq(withdrawer, WUSER1, "Withdrawer");
        assertEq(token, TOKEN1, "Token");
        assertEq(amount, amount1, "Amount");
        (more, withdrawer, token, amount) = flowRateWithdrawalQueue.dequeueWithdrawal(RUSER1);
        assertEq(more, false, "More");
        assertEq(withdrawer, WUSER2, "Withdrawer");
        assertEq(token, TOKEN2, "Token");
        assertEq(amount, amount2, "Amount");
    }
    

}




