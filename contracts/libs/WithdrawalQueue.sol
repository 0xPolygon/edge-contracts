// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Withdrawal {
    uint256 amount;
    uint256 epoch;
}

struct WithdrawalQueue {
    uint256 head;
    uint256 tail;
    mapping(uint256 => Withdrawal) withdrawals;
}

library WithdrawalQueueLib {
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

    // slither-disable-next-line dead-code
    function length(WithdrawalQueue storage self) internal view returns (uint256) {
        return self.tail - self.head;
    }

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

    function pending(WithdrawalQueue storage self, uint256 currentEpoch) internal view returns (uint256 amount) {
        for (uint256 i = self.tail - 1; i >= self.head; i--) {
            Withdrawal memory withdrawal = self.withdrawals[i];
            if (withdrawal.epoch <= currentEpoch) break;
            amount += withdrawal.amount;
            if (i == 0) break;
        }
    }
}
