// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IValidator.sol";

/**
 * @notice data type reperesnting validator in queue (not active)
 * @param validator the address of the validator
 * @param stake the amount staked by the validator
 * @param delegation the amount delegated to this validator
 */
struct QueuedValidator {
    address validator;
    int256 stake;
    int256 delegation;
}

/**
 * @notice data type for the management of the queue
 * @param indices position of a validator in the queue array
 * @param queue array of QueuedValidators
 */
struct ValidatorQueue {
    mapping(address => uint256) indices;
    QueuedValidator[] queue;
}

/**
 * @title Validator Queue Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice library to manage the queue of potenital block validators
 */
library ValidatorQueueLib {
    /**
     * @notice inserts a validator into the queue
     * @param self ValidatorQueue struct
     * @param validator address of the validator
     * @param stake amount staked by validator
     * @param delegation amount delegated to validator
     */
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
            QueuedValidator storage queuedValidator = self.queue[indexOf(self, validator)];
            queuedValidator.stake += stake;
            queuedValidator.delegation += delegation;
        }
    }

    /**
     * @notice deletes data from a specific index in the queue
     * @param self ValidatorQueue struct
     * @param validator address of the validator being removed
     */
    function resetIndex(ValidatorQueue storage self, address validator) internal {
        self.indices[validator] = 0;
    }

    /**
     * @notice reinitializes the validator queue, removing all current data
     * @param self ValidatorQueue struct
     */
    function reset(ValidatorQueue storage self) internal {
        delete self.queue;
    }

    /**
     * @notice returns the queue
     * @param self the ValidatorQueue struct
     * @return QueuedValidator[]
     */
    function get(ValidatorQueue storage self) internal view returns (QueuedValidator[] storage) {
        return self.queue;
    }

    /**
     * @notice returns if a specific validator is in the queue
     * @dev the queue starts from index 1 (not 0) to facilitate this
     * @param self the ValidatorQueue struct
     * @param validator the address of the validator to check
     * @return bool indicating if the validator is in the queue (true) or not
     */
    function waiting(ValidatorQueue storage self, address validator) internal view returns (bool) {
        return self.indices[validator] != 0;
    }

    /**
     * @notice convenience function to return the stake of a validator in the queue
     * @param self the ValidatorQueue struct
     * @param validator the address of the validator to check the stake of
     * @return int256 stake of the validator
     */
    function pendingStake(ValidatorQueue storage self, address validator) internal view returns (int256) {
        if (!waiting(self, validator)) return 0;
        return self.queue[indexOf(self, validator)].stake;
    }

    /**
     * @notice convenience function to return the funds delegated to a pending validator
     * @param self the ValidatorQueue struct
     * @param validator the address of the validator to check the delegated funds of
     * @return int256 funds delegated to the validator
     */
    // slither-disable-next-line dead-code
    function pendingDelegation(ValidatorQueue storage self, address validator) internal view returns (int256) {
        if (!waiting(self, validator)) return 0;
        return self.queue[indexOf(self, validator)].delegation;
    }

    /**
     * @notice returns index of a specific validator
     * @dev indexes returned from this function start from 0
     * @param self the ValidatorQueue struct
     * @param validator address of the validator whose index is being queried
     * @return index the index of the validator in the queue
     */
    function indexOf(ValidatorQueue storage self, address validator) private view returns (uint256 index) {
        index = self.indices[validator];
        // never triggered currently
        // assert(index != 0);
        return index - 1;
    }
}
