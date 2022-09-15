// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {QueuedValidator, ValidatorQueue, ValidatorQueueLib} from "contracts/libs/ValidatorQueue.sol";
import "contracts/interfaces/IValidator.sol";

import "../utils/TestPlus.sol";

abstract contract EmptyState is TestPlus {
    int256 constant STAKE = 2 ether;
    int256 constant DELEGATED = 0.5 ether;

    address account;
    ValidatorQueue queue;

    function setUp() public virtual {
        account = makeAddr("account");
    }
}

contract ValidatorQueueTest_EmptyState is EmptyState {
    using ValidatorQueueLib for ValidatorQueue;

    function testInsert_New() public {
        queue.insert(account, STAKE, DELEGATED);

        assertEq(queue.indices[account], 1);
        assertEq(queue.queue.length, 1);
        assertEq(queue.queue[0], QueuedValidator(account, STAKE, DELEGATED));
    }
}

abstract contract NonEmptyState is EmptyState {
    using ValidatorQueueLib for ValidatorQueue;

    QueuedValidator[] queuedValidators;
    address newAccount;

    function setUp() public virtual override {
        super.setUp();
        queue.insert(account, STAKE, DELEGATED);
        queuedValidators.push(QueuedValidator(account, STAKE, DELEGATED));
        newAccount = makeAddr("newAccount");
    }
}

contract ValidatorQueueTest_NonEmptyState is NonEmptyState {
    using ValidatorQueueLib for ValidatorQueue;

    function testInsert_Queued() public {
        queue.insert(account, -1, -1); // remove

        assertEq(queue.indices[account], 1);
        assertEq(queue.queue.length, 1);
        assertEq(queue.queue[0], QueuedValidator(account, STAKE - 1, DELEGATED - 1));
    }

    function testInsert_New() public {
        queue.insert(newAccount, STAKE / 2, DELEGATED / 2);

        assertEq(queue.indices[newAccount], 2);
        assertEq(queue.queue.length, 2);
        assertEq(queue.queue[1], QueuedValidator(newAccount, STAKE / 2, DELEGATED / 2));
    }

    function testResetIndex() public {
        queue.resetIndex(account);
        assertEq(queue.indices[account], 0);
    }

    function testReset() public {
        delete queuedValidators;

        queue.reset();

        assertEq(queue.queue, queuedValidators);
    }

    function testGet() public {
        assertEq(queue.get(), queuedValidators);
    }

    function testWaiting() public {
        assertFalse(queue.waiting(newAccount));
        assertTrue(queue.waiting(account));
    }

    function testPendingStake() public {
        assertEq(queue.pendingStake(newAccount), 0);
        assertEq(queue.pendingStake(account), STAKE);
    }

    function testPendingDelegation() public {
        assertEq(queue.pendingDelegation(newAccount), 0);
        assertEq(queue.pendingDelegation(account), DELEGATED);
    }
}
