// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice data type for withdrawals
 * @param amount the amount to withdraw
 * @param epoch the epoch of the withdrawal
 */
struct Withdrawal {
    uint256 amount;
    uint256 epoch;
}

/**
 * @notice data type for managing the withdrawal queue
 * @param head earliest index
 * @param tail latest index
 * @param withdrawals Withdrawal structs by index
 */
struct WithdrawalQueue {
    uint256 head;
    uint256 tail;
    mapping(uint256 => Withdrawal) withdrawals;
}

/**
 * @title Withdrawal Queue Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice queue for stake withdrawals
 */
library WithdrawalQueueLib {
    /**
     * @notice add a withdrawal to the queue
     * @param self the WithdrawalQueue struct
     * @param amount the amount to withdraw
     * @param epoch the epoch to withdraw
     */
    function append(
        WithdrawalQueue storage self,
        uint256 amount,
        uint256 epoch
    ) internal {
        assert(amount != 0);
        uint256 head = self.head;
        uint256 tail = self.tail;

        // first element in empty list
        if (tail == head) {
            self.withdrawals[tail] = Withdrawal(amount, epoch);
            self.tail++;
            return;
        }

        uint256 latestEpoch = self.withdrawals[tail - 1].epoch;
        assert(epoch >= latestEpoch);
        if (latestEpoch < epoch) {
            // new withdrawal for next epoch
            self.withdrawals[tail] = Withdrawal(amount, epoch);
            self.tail++;
        } else {
            // adding to existing withdrawal for next epoch
            self.withdrawals[tail - 1].amount += amount;
        }
    }

    /**
     * @notice returns the length between the head and tail of the queue
     * @param self the WithdrawalQueue struct
     * @return uint256 the length of the queue
     */
    // slither-disable-next-line dead-code
    function length(WithdrawalQueue storage self) internal view returns (uint256) {
        return self.tail - self.head;
    }

    /**
     * @notice returns the amount withdrawable up to a specified epoch
     * and new head index at that point
     * @param self the WithdrawalQueue struct
     * @param currentEpoch the epoch to check until
     * @return amount the amount withdrawable through the specified epoch
     * @return newHead the head of the queue if once these epochs have passed
     */
    function withdrawable(WithdrawalQueue storage self, uint256 currentEpoch)
        internal
        view
        returns (uint256 amount, uint256 newHead)
    {
        for (newHead = self.head; newHead < self.tail; newHead++) {
            Withdrawal memory withdrawal = self.withdrawals[newHead];
            if (withdrawal.epoch > currentEpoch) return (amount, newHead);
            amount += withdrawal.amount;
        }
    }

    /**
     * @notice returns the amount withdrawable up to a specified epoch
     * @param self the WithdrawalQueue struct
     * @param currentEpoch the epoch to check until
     * @return amount the amount withdrawable through the specified epoch
     */
    function pending(WithdrawalQueue storage self, uint256 currentEpoch) internal view returns (uint256 amount) {
        for (uint256 i = self.tail - 1; i >= self.head; i--) {
            Withdrawal memory withdrawal = self.withdrawals[i];
            if (withdrawal.epoch <= currentEpoch) break;
            amount += withdrawal.amount;
            if (i == 0) break;
        }
    }
}
