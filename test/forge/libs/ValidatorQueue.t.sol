// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@utils/Test.sol";

import {QueuedValidator, ValidatorQueue, ValidatorQueueLib} from "contracts/libs/ValidatorQueue.sol";
import "contracts/interfaces/IValidator.sol";

abstract contract EmptyState is Test {
    int256 constant STAKE = 2 ether;
    int256 constant DELEGATED = 0.5 ether;

    address account;

    ValidatorQueueLibUser validatorQueueLibUser;

    function setUp() public virtual {
        account = makeAddr("account");
        validatorQueueLibUser = new ValidatorQueueLibUser();
    }
}

contract ValidatorQueueTest_EmptyState is EmptyState {
    function testInsert_New() public {
        validatorQueueLibUser.insert(account, STAKE, DELEGATED);

        assertEq(validatorQueueLibUser.indicesGetter(account), 1);
        assertEq(validatorQueueLibUser.queueGetter().length, 1);
        assertEq(validatorQueueLibUser.queueGetter()[0], QueuedValidator(account, STAKE, DELEGATED));
    }
}

abstract contract NonEmptyState is EmptyState {
    QueuedValidator[] queuedValidators;
    address newAccount;

    function setUp() public virtual override {
        super.setUp();
        validatorQueueLibUser.insert(account, STAKE, DELEGATED);
        queuedValidators.push(QueuedValidator(account, STAKE, DELEGATED));
        newAccount = makeAddr("newAccount");
    }
}

contract ValidatorQueueTest_NonEmptyState is NonEmptyState {
    function testInsert_Queued() public {
        validatorQueueLibUser.insert(account, -1, -1); // remove

        assertEq(validatorQueueLibUser.indicesGetter(account), 1);
        assertEq(validatorQueueLibUser.queueGetter().length, 1);
        assertEq(validatorQueueLibUser.queueGetter()[0], QueuedValidator(account, STAKE - 1, DELEGATED - 1));
    }

    function testInsert_New() public {
        validatorQueueLibUser.insert(newAccount, STAKE / 2, DELEGATED / 2);

        assertEq(validatorQueueLibUser.indicesGetter(newAccount), 2);
        assertEq(validatorQueueLibUser.queueGetter().length, 2);
        assertEq(validatorQueueLibUser.queueGetter()[1], QueuedValidator(newAccount, STAKE / 2, DELEGATED / 2));
    }

    function testResetIndex() public {
        validatorQueueLibUser.resetIndex(account);
        assertEq(validatorQueueLibUser.indicesGetter(account), 0);
    }

    function testReset() public {
        delete queuedValidators;

        validatorQueueLibUser.reset();

        assertEq(validatorQueueLibUser.queueGetter(), queuedValidators);
    }

    function testGet() public {
        assertEq(validatorQueueLibUser.get(), queuedValidators);
    }

    function testWaiting() public {
        assertFalse(validatorQueueLibUser.waiting(newAccount));
        assertTrue(validatorQueueLibUser.waiting(account));
    }

    function testPendingStake() public {
        assertEq(validatorQueueLibUser.pendingStake(newAccount), 0);
        assertEq(validatorQueueLibUser.pendingStake(account), STAKE);
    }

    function testPendingDelegation() public {
        assertEq(validatorQueueLibUser.pendingDelegation(newAccount), 0);
        assertEq(validatorQueueLibUser.pendingDelegation(account), DELEGATED);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract ValidatorQueueLibUser {
    ValidatorQueue queue;

    function insert(address validator, int256 stake, int256 delegation) external {
        ValidatorQueueLib.insert(queue, validator, stake, delegation);
    }

    function resetIndex(address validator) external {
        ValidatorQueueLib.resetIndex(queue, validator);
    }

    function reset() external {
        ValidatorQueueLib.reset(queue);
    }

    function get() external view returns (QueuedValidator[] memory) {
        QueuedValidator[] memory r = ValidatorQueueLib.get(queue);
        return r;
    }

    function waiting(address validator) external view returns (bool) {
        bool r = ValidatorQueueLib.waiting(queue, validator);
        return r;
    }

    function pendingStake(address validator) external view returns (int256) {
        int256 r = ValidatorQueueLib.pendingStake(queue, validator);
        return r;
    }

    function pendingDelegation(address validator) external view returns (int256) {
        int256 r = ValidatorQueueLib.pendingDelegation(queue, validator);
        return r;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        GETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function indicesGetter(address a) external view returns (uint256) {
        return queue.indices[a];
    }

    function queueGetter() external view returns (QueuedValidator[] memory) {
        return queue.queue;
    }
}
