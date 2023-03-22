// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {Withdrawal, WithdrawalQueue, WithdrawalQueueLib} from "contracts/lib/WithdrawalQueue.sol";

abstract contract EmptyState is Test {
    uint256 constant AMOUNT = 2 ether;
    uint256 EPOCH = 1;

    WithdrawalQueueLibUser withdrawalQueueLibUser;

    function setUp() public virtual {
        withdrawalQueueLibUser = new WithdrawalQueueLibUser();
    }
}

contract WithdrawalQueueTest_EmptyState is EmptyState {
    function testCannotAppend_ZeroAmount() public {
        vm.expectRevert(stdError.assertionError);
        withdrawalQueueLibUser.append(0, 0);
    }

    function testAppend() public {
        withdrawalQueueLibUser.append(AMOUNT, EPOCH);

        assertEq(withdrawalQueueLibUser.headGetter(), 0);
        assertEq(withdrawalQueueLibUser.tailGetter(), 1);
        assertEq(withdrawalQueueLibUser.withdrawalsGetter(0), Withdrawal(AMOUNT, EPOCH));
    }
}

abstract contract SingleState is EmptyState {
    function setUp() public virtual override {
        super.setUp();
        withdrawalQueueLibUser.append(AMOUNT, EPOCH);
    }
}

contract WithdrawalQueueTest_SingleState is SingleState {
    function testCannotAppend_OldEpoch() public {
        vm.expectRevert(stdError.assertionError);
        withdrawalQueueLibUser.append(AMOUNT, EPOCH - 1);
    }

    function testAppend_SameEpoch() public {
        withdrawalQueueLibUser.append(AMOUNT, EPOCH);

        assertEq(withdrawalQueueLibUser.headGetter(), 0);
        assertEq(withdrawalQueueLibUser.tailGetter(), 1);
        assertEq(withdrawalQueueLibUser.withdrawalsGetter(0), Withdrawal(AMOUNT * 2, EPOCH));
    }

    function testAppend_NextEpoch() public {
        withdrawalQueueLibUser.append(AMOUNT / 2, EPOCH + 1);

        assertEq(withdrawalQueueLibUser.headGetter(), 0);
        assertEq(withdrawalQueueLibUser.tailGetter(), 2);
        assertEq(withdrawalQueueLibUser.withdrawalsGetter(1), Withdrawal(AMOUNT / 2, EPOCH + 1));
    }
}

abstract contract MultipleState is SingleState {
    function setUp() public virtual override {
        // start with empty queue
        withdrawalQueueLibUser = new WithdrawalQueueLibUser();
    }

    /// @notice Fill queue and randomize head
    /// @dev Use in fuzz tests
    function _fillQueue(uint128[] memory amounts) internal {
        for (uint256 i; i < amounts.length; ) {
            uint256 amount = amounts[i];
            if (amount > 0) withdrawalQueueLibUser.append(amount, i);

            unchecked {
                ++i;
            }
        }
        vm.assume(withdrawalQueueLibUser.tailGetter() > 0);
        withdrawalQueueLibUser.headSetter(type(uint256).max % withdrawalQueueLibUser.tailGetter());
    }
}

contract WithdrawalQueue_MultipleState is MultipleState {
    function testLength(uint128[] memory amounts) public {
        _fillQueue(amounts);

        assertEq(
            withdrawalQueueLibUser.length(),
            withdrawalQueueLibUser.tailGetter() - withdrawalQueueLibUser.headGetter()
        );
    }

    function testWithdrawable(uint128[] memory amounts, uint256 currentEpoch) public {
        _fillQueue(amounts);
        uint256 expectedAmount;
        uint256 expectedNewHead;
        currentEpoch = bound(
            currentEpoch,
            withdrawalQueueLibUser.headGetter(),
            withdrawalQueueLibUser.tailGetter() - 1
        );
        // calculate amount and newHead
        expectedNewHead = withdrawalQueueLibUser.headGetter();
        Withdrawal memory withdrawal = withdrawalQueueLibUser.withdrawalsGetter(expectedNewHead);
        while (expectedNewHead < withdrawalQueueLibUser.tailGetter() && withdrawal.epoch <= currentEpoch) {
            expectedAmount += withdrawal.amount;
            ++expectedNewHead;

            withdrawal = withdrawalQueueLibUser.withdrawalsGetter(expectedNewHead);
        }

        (uint256 amount, uint256 newHead) = withdrawalQueueLibUser.withdrawable(currentEpoch);
        assertEq(amount, expectedAmount, "Amount");
        assertEq(newHead, expectedNewHead, "New head");
    }

    function testPending(uint128[] memory amounts, uint256 currentEpoch) public {
        _fillQueue(amounts);
        uint256 expectedAmount;
        currentEpoch = bound(
            currentEpoch,
            withdrawalQueueLibUser.headGetter(),
            withdrawalQueueLibUser.tailGetter() - 1
        );
        // calculate amount
        uint256 headCursor = withdrawalQueueLibUser.headGetter();
        Withdrawal memory withdrawal = withdrawalQueueLibUser.withdrawalsGetter(headCursor);
        while (headCursor < withdrawalQueueLibUser.tailGetter()) {
            if (withdrawal.epoch > currentEpoch) expectedAmount += withdrawal.amount;
            withdrawal = withdrawalQueueLibUser.withdrawalsGetter(++headCursor);
        }

        assertEq(withdrawalQueueLibUser.pending(currentEpoch), expectedAmount);
    }

    function testPending_HeadZero() public {
        withdrawalQueueLibUser.append(1 ether, 2);

        // should break and not underflow
        assertEq(withdrawalQueueLibUser.pending(1), 1 ether);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                 MOCKS
 //////////////////////////////////////////////////////////////////////////*/

contract WithdrawalQueueLibUser {
    WithdrawalQueue queue;

    function append(uint256 amount, uint256 epoch) external {
        WithdrawalQueueLib.append(queue, amount, epoch);
    }

    function length() external view returns (uint256) {
        uint256 r = WithdrawalQueueLib.length(queue);
        return r;
    }

    function withdrawable(uint256 currentEpoch) external view returns (uint256, uint256) {
        (uint256 a, uint256 b) = WithdrawalQueueLib.withdrawable(queue, currentEpoch);
        return (a, b);
    }

    function pending(uint256 currentEpoch) external view returns (uint256 amount) {
        uint256 r = WithdrawalQueueLib.pending(queue, currentEpoch);
        return r;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                         GETTERS
     //////////////////////////////////////////////////////////////////////////*/

    function headGetter() external view returns (uint256) {
        return queue.head;
    }

    function tailGetter() external view returns (uint256) {
        return queue.tail;
    }

    function withdrawalsGetter(uint256 a) external view returns (Withdrawal memory) {
        return queue.withdrawals[a];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                         SETTERS
     //////////////////////////////////////////////////////////////////////////*/

    function headSetter(uint256 a) external {
        queue.head = a;
    }
}
