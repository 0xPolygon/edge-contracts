// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/lib/IWithdrawalQueue.sol";

/**
 * @title Withdrawal Queue Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice queue for withdrawals
 */
library WithdrawalQueueLib {
    /**
     * @notice update queue with new withdrawal data
     * @dev if there is already a withdrawal for the epoch being submitted,
     * the amount will be added to that epoch; otherwise, a new withdrawal
     * struct will be created in the queue
     * @param self the WithdrawalQueue struct
     * @param amount the amount to withdraw
     * @param epoch the epoch to withdraw
     */
    function append(WithdrawalQueue storage self, uint256 amount, uint256 epoch) internal {
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
     * (which is the amount of unprocessed withdrawals)
     * @param self the WithdrawalQueue struct
     * @return uint256 the length between head and tail (unproceesed withdrawals)
     */
    // slither-disable-next-line dead-code
    function length(WithdrawalQueue storage self) internal view returns (uint256) {
        return self.tail - self.head;
    }

    /**
     * @notice returns the amount withdrawable through a specified epoch
     * and new head index at that point
     * @dev meant to be used with the current epoch being passed in
     * @param self the WithdrawalQueue struct
     * @param currentEpoch the epoch to check until
     * @return amount the amount withdrawable through the specified epoch
     * @return newHead the head of the queue once these withdrawals have been processed
     */
    function withdrawable(
        WithdrawalQueue storage self,
        uint256 currentEpoch
    ) internal view returns (uint256 amount, uint256 newHead) {
        for (newHead = self.head; newHead < self.tail; newHead++) {
            Withdrawal memory withdrawal = self.withdrawals[newHead];
            if (withdrawal.epoch > currentEpoch) return (amount, newHead);
            amount += withdrawal.amount;
        }
    }

    /**
     * @notice returns the amount withdrawable beyond a specified epoch
     * @dev meant to be used with the current epoch being passed in
     * @param self the WithdrawalQueue struct
     * @param currentEpoch the epoch to check from
     * @return amount the amount withdrawable from beyond the specified epoch
     */
    function pending(WithdrawalQueue storage self, uint256 currentEpoch) internal view returns (uint256 amount) {
        uint256 tail = self.tail;
        if (tail == 0) return 0;
        for (uint256 i = tail - 1; i >= self.head; i--) {
            Withdrawal memory withdrawal = self.withdrawals[i];
            if (withdrawal.epoch <= currentEpoch) break;
            amount += withdrawal.amount;
            if (i == 0) break;
        }
    }
}
