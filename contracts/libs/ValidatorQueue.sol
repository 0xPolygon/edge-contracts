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
    uint256 count;
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
            // use index starting with 1
            index = ++self.count;
            self.indices[validator] = index;
            self.queue[index] = QueuedValidator(validator, stake, delegation);
        } else {
            // update values
            QueuedValidator storage queuedValidator = self.queue[index];
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
        self.queue = new QueuedValidator[](0);
        self.count = 0;
    }
}
