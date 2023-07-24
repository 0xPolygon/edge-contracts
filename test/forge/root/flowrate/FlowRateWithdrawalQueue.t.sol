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

    address constant USER = address(12345);

    function setUp() public virtual  {
        flowRateWithdrawalQueue = new FlowRateWithdrawalQueueT();
    }
}


contract UninitializedFlowRateWithdrawalQueueTests is FlowRateWithdrawalQueueTests {
    function testUninitWithdrawalQueue() public {
        uint256 delay = flowRateWithdrawalQueue.withdrawalDelay();
        assertEq(delay, 0, "Delay");
    }

    function testPendingWithdrawals() public {
        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = flowRateWithdrawalQueue.getPendingWithdrawals(USER);
        assertEq(pending.length, 0, "Pending withdrawal length");

    }
}

abstract contract ControlFlowRateWithdrawalQueueTests is FlowRateWithdrawalQueueTests {
    event WithdrawalDelayUpdated(uint256 delay);

    function testInitWithdrawalQueue() public {
        uint256 expectedDelay = flowRateWithdrawalQueue.DEFAULT_WITHDRAW_DELAY();
        vm.expectEmit(false, false, false, true);
        emit WithdrawalDelayUpdated(expectedDelay);
        flowRateWithdrawalQueue.init();
        uint256 delay = flowRateWithdrawalQueue.withdrawalDelay();
        assertEq(delay, expectedDelay, "Delay");
    }
}




