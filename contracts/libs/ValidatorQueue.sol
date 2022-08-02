// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IValidator.sol";

struct QueuedValidator {
    address validator;
    int256 stake;
    int256 delegation;
}

struct ValidatorQueue {
    mapping(address => uint256) indices;
    QueuedValidator[] queue;
}

library ValidatorQueueLib {
    function insert(
        ValidatorQueue storage self,
        address validator,
        int256 stake,
        int256 delegation
    ) internal {
        uint256 index = self.indices[validator];
        if (index == 0) {
            // insert into queue
            // use index starting with 1, 0 is empty by default for easier checking of pending balances
            index = self.queue.length + 1;
            self.indices[validator] = index;
            self.queue.push(QueuedValidator(validator, stake, delegation));
        } else {
            // update values
            QueuedValidator storage queuedValidator = self.queue[
                indexOf(self, validator)
            ];
            queuedValidator.stake += stake;
            queuedValidator.delegation += delegation;
        }
    }

    function resetIndex(ValidatorQueue storage self, address validator)
        internal
    {
        self.indices[validator] = 0;
    }

    function reset(ValidatorQueue storage self) internal {
        delete self.queue;
    }

    function get(ValidatorQueue storage self)
        internal
        view
        returns (QueuedValidator[] storage)
    {
        return self.queue;
    }

    function pendingStake(ValidatorQueue storage self, address validator)
        internal
        view
        returns (int256)
    {
        return self.queue[indexOf(self, validator)].stake;
    }

    function pendingDelegation(ValidatorQueue storage self, address validator)
        internal
        view
        returns (int256)
    {
        return self.queue[indexOf(self, validator)].delegation;
    }

    function indexOf(ValidatorQueue storage self, address validator)
        private
        view
        returns (uint256 index)
    {
        index = self.indices[validator];
        assert(index != 0);
        return index - 1;
    }
}
