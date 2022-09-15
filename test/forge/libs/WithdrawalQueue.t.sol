// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Withdrawal, WithdrawalQueue, WithdrawalQueueLib} from "contracts/libs/WithdrawalQueue.sol";

import "../utils/TestPlus.sol";

abstract contract EmptyState is TestPlus {
    uint256 constant AMOUNT = 2 ether;
    uint256 EPOCH = 1;

    WithdrawalQueue queue;
}

contract WithdrawalQueueTest_EmptyState is EmptyState {
    using WithdrawalQueueLib for WithdrawalQueue;

    function testCannotAppend_ZeroAmount() public {
        vm.expectRevert(stdError.assertionError);
        queue.append(0, 0);
    }

    function testAppend() public {
        queue.append(AMOUNT, EPOCH);

        assertEq(queue.head, 0);
        assertEq(queue.tail, 1);
        assertEq(queue.withdrawals[0], Withdrawal(AMOUNT, EPOCH));
    }
}

abstract contract SingleState is EmptyState {
    using WithdrawalQueueLib for WithdrawalQueue;

    function setUp() public virtual {
        queue.append(AMOUNT, EPOCH);
    }
}

contract WithdrawalQueueTest_SingleState is SingleState {
    using WithdrawalQueueLib for WithdrawalQueue;

    function testCannotAppend_OldEpoch() public {
        vm.expectRevert(stdError.assertionError);
        queue.append(AMOUNT, EPOCH - 1);
    }

    function testAppend_SameEpoch() public {
        queue.append(AMOUNT, EPOCH);

        assertEq(queue.head, 0);
        assertEq(queue.tail, 1);
        assertEq(queue.withdrawals[0], Withdrawal(AMOUNT * 2, EPOCH));
    }

    function testAppend_NextEpoch() public {
        queue.append(AMOUNT / 2, EPOCH + 1);

        assertEq(queue.head, 0);
        assertEq(queue.tail, 2);
        assertEq(queue.withdrawals[1], Withdrawal(AMOUNT / 2, EPOCH + 1));
    }
}

abstract contract MultipleState is SingleState {
    using WithdrawalQueueLib for WithdrawalQueue;

    function setUp() public virtual override {
        // start with empty queue
    }

    /// @notice Fill queue and randomize head
    /// @dev Use in fuzz tests
    function _fillQueue(uint128[] memory amounts) internal {
        for (uint256 i; i < amounts.length; ) {
            uint256 amount = amounts[i];
            if (amount > 0) queue.append(amount, i);

            unchecked {
                ++i;
            }
        }
        vm.assume(queue.tail > 0);
        queue.head = type(uint256).max % queue.tail;
    }
}

contract WithdrawalQueue_MultipleState is MultipleState {
    using WithdrawalQueueLib for WithdrawalQueue;

    function testLength(uint128[] memory amounts) public {
        _fillQueue(amounts);

        assertEq(queue.length(), queue.tail - queue.head);
    }

    function testWithdrawable(uint128[] memory amounts, uint256 currentEpoch) public {
        _fillQueue(amounts);
        uint256 expectedAmount;
        uint256 expectedNewHead;
        currentEpoch = bound(currentEpoch, queue.head, queue.tail - 1);
        // calculate amount and newHead
        expectedNewHead = queue.head;
        Withdrawal memory withdrawal = queue.withdrawals[expectedNewHead];
        while (expectedNewHead < queue.tail && withdrawal.epoch <= currentEpoch) {
            expectedAmount += withdrawal.amount;
            ++expectedNewHead;

            withdrawal = queue.withdrawals[expectedNewHead];
        }

        (uint256 amount, uint256 newHead) = queue.withdrawable(currentEpoch);
        assertEq(amount, expectedAmount, "Amount");
        assertEq(newHead, expectedNewHead, "New head");
    }

    function testPending(uint128[] memory amounts, uint256 currentEpoch) public {
        _fillQueue(amounts);
        uint256 expectedAmount;
        currentEpoch = bound(currentEpoch, queue.head, queue.tail - 1);
        // calculate amount
        uint256 headCursor = queue.head;
        Withdrawal memory withdrawal = queue.withdrawals[headCursor];
        while (headCursor < queue.tail) {
            if (withdrawal.epoch > currentEpoch) expectedAmount += withdrawal.amount;
            withdrawal = queue.withdrawals[++headCursor];
        }

        assertEq(queue.pending(currentEpoch), expectedAmount);
    }
}
