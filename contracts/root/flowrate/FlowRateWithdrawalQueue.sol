// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Flow Rate Withdrawal Queue
 * @author Immutable Pty Ltd (Peter Robinson @drinkcoffee)
 * @notice Queue for withdrawals from the RootERC20PredicateFlowRate.
 * @dev    When withdrawals are delayed, they are put in the queue defined in this contract.
 *         To match the WithdrawalQueue.sol used for staking, new withdrawal requests are added
 *         to the tail of the queue. Withdrawals are dequeued from the head of the queue.
 *         Note: This code is part of RootERC20PredicateFlowRate. It has been separated out
 *         to make it easier to understand the functionality.
 *         Note that this contract is upgradeable.
 */
abstract contract FlowRateWithdrawalQueue {
    // One day
    uint256 private constant DEFAULT_WITHDRAW_DELAY = 60 * 60 * 24;

    // A single token withdrawal for a user.
    struct PendingWithdrawal {
        // The account that initiated the crosschain transfer on the child chain.
        address withdrawer;
        // The token being withdrawn.
        address token;
        // The number of tokens.
        uint256 amount;
        // The time when the withdraw was requested. The pending withdrawal can be
        // withdrawn at time timestamp + withdrawalDelay. Note that it is possible
        // that the withdrawalDelay is updated while the withdrawal is still pending.
        uint256 timestamp;
    }
    struct PendingWithdrawalQueue {
        // Index of the head of the queue.
        uint256 head;
        // Index of the tail of the queue.
        uint256 tail;
        // Mapping of index into the queue to queue item.
        mapping(uint256 => PendingWithdrawal) items;
    }
    // Mapping of user addresses to withdrawal queue.
    mapping(address => PendingWithdrawalQueue) public pendingWithdrawals;

    // The amount of time between a withdrawal request and a user being allowed to withdraw.
    uint256 public withdrawalDelay;

    // Indicates that the user must wait until *time* before calling withdraw
    event PleaseWait(uint256 time);

    /**
     * @notice Initilization function for FlowRateWithdrawalQueue
     * @dev Can only be called once.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __FlowRateWithdrawalQueue_init() internal {
        withdrawalDelay = DEFAULT_WITHDRAW_DELAY;
    }

    /**
     * @notice Set the delay in seconds between when a withdrawal is requested and
     *         when it can be withdrawn.
     * @param delay Withdrawal delay in seconds.
     */
    function _setWithdrawalDelay(uint256 delay) internal {
        withdrawalDelay = delay;
    }

    /**
     * @notice Add a withdrawal request to the queue.
     * @param receiver The account that the tokens should be transferred to.
     * @param withdrawer The account that initiated the crosschain transfer on the child chain.
     * @param token The token to withdraw.
     * @param amount the amount to withdraw.
     */
    function _enqueueWithdrawal(address receiver, address withdrawer, address token, uint256 amount) internal {
        PendingWithdrawalQueue storage queue = pendingWithdrawals[receiver];
        uint256 tail = queue.tail;
        // solhint-disable-next-line not-rely-on-time
        queue.items[tail] = PendingWithdrawal(token, withdrawer, amount, block.timestamp);
        queue.tail = tail + 1;
    }

    /**
     * @notice Fetch a withdrawal request from the queue.
     * @param receiver The account that the tokens should be transferred to.
     * @return more true if there are more queued withdrawals after the one being returned with
     *               this function call.
     * @return withdrawer The account on the child chain that initiated the crosschain transfer.
     * @return token The token to transfer to the receiver.
     * @return amount The number of tokens to transfer to the receiver.
     */
    function _dequeueWithdrawal(
        address receiver
    ) internal returns (bool more, address withdrawer, address token, uint256 amount) {
        PendingWithdrawalQueue storage queue = pendingWithdrawals[receiver];
        uint256 head = queue.head;
        uint256 tail = queue.tail;

        // Check if the queue is empty.
        if (head == tail) {
            return (false, address(0), address(0), 0);
        }

        more = head + 1 != tail;

        PendingWithdrawal storage withdrawal = queue.items[head];
        // Note: Add the withdrawal delay here, and not when enqueuing to allow changes
        // to withdrawal delay to have effect on in progress withdrawals.
        uint256 withdrawalTime = withdrawal.timestamp + withdrawalDelay;
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < withdrawalTime) {
            emit PleaseWait(withdrawalTime);
            return (more, address(0), address(0), 0);
        }

        queue.head = head + 1;
        withdrawer = withdrawal.withdrawer;
        token = withdrawal.token;
        amount = withdrawal.amount;

        // Zeroize the old queue item to save some gas.
        delete queue.items[head];
    }

    /**
     * @notice Fetch the queue of pending withdrawals for an address.
     * @param receiver The account to fetch the queue for.
     * @return pending Array of pending withdrawals.
     */
    function getPendingWithdrawals(address receiver) external view returns (PendingWithdrawal[] memory pending) {
        PendingWithdrawalQueue storage queue = pendingWithdrawals[receiver];
        uint256 head = queue.head;
        uint256 tail = queue.tail;

        pending = new PendingWithdrawal[](tail - head);
        for (uint256 i = 0; i < pending.length; i++) {
            pending[i] = queue.items[head + i];
        }
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
