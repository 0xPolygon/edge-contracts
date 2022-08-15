// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Withdrawal, WithdrawalQueue, WithdrawalQueueLib} from "contracts/libs/WithdrawalQueue.sol";

import "../utils/TestPlus.sol";

// TODO: improve
contract WithdrawalQueueTest is TestPlus {
    using WithdrawalQueueLib for WithdrawalQueue;

    WithdrawalQueue withdrawalQueue;

    function setUp() public {}

    function testCannotAppend_AmountZero() public {
        vm.expectRevert(stdError.assertionError);
        withdrawalQueue.append(0, 0);
    }

    function testAppend_EmptyQueue() public {
        uint256 amount = 1 ether;
        uint256 epoch = 1;

        withdrawalQueue.append(amount, epoch);
        Withdrawal memory withdrawal = withdrawalQueue.withdrawals[0];

        assertEq(withdrawalQueue.head, 0);
        assertEq(withdrawalQueue.tail, 1);
        assertEq(withdrawal.amount, amount);
        assertEq(withdrawal.epoch, epoch);
    }

    function testCannotAppend_EndedEpoch() public {
        uint256 amount = 1 ether;
        uint256 epoch = 1;
        withdrawalQueue.append(amount, epoch);

        vm.expectRevert(stdError.assertionError);
        withdrawalQueue.append(amount, epoch - 1);
    }

    /*function testAppend_NewWithdrawal() public {
        uint256 amount = 1 ether;
        uint256 epoch = 1;
        uint256 laterEpoch = epoch + 1;
        withdrawalQueue.append(amount, epoch);

        withdrawalQueue.append(amount, laterEpoch);
        Withdrawal memory withdrawal = withdrawalQueue.withdrawals[1];

        assertEq(withdrawalQueue.head, 0);
        assertEq(withdrawalQueue.tail, 2);
        assertEq(withdrawal.amount, amount);
        assertEq(withdrawal.epoch, laterEpoch);
    }

    function testAppend_ExistingWithdrawal() public {
        uint256 amount = 1 ether;
        uint256 epoch = 1;
        withdrawalQueue.append(amount, epoch);

        // this is for same epoch
        withdrawalQueue.append(amount, epoch);
        Withdrawal memory withdrawal = withdrawalQueue.withdrawals[0];

        assertEq(withdrawalQueue.head, 0);
        assertEq(withdrawalQueue.tail, 1);
        assertEq(withdrawal.amount, amount * 2);
        assertEq(withdrawal.epoch, epoch);
    }

    function testLength() public {
        uint256 amount = 1 ether;
        uint256 epoch = 1;
        withdrawalQueue.append(amount, epoch);

        assertEq(withdrawalQueue.length(), 1);
    }

    function testWithdrawable() public {
        uint256 amount = 1 ether;
        uint256 epoch = 0;
        withdrawalQueue.append(amount, epoch);
        withdrawalQueue.append(amount, epoch + 1);

        assertEq(withdrawalQueue.withdrawable(epoch + 1), amount * 2);
    }

    function testPending() public {
        
    }*/
}
