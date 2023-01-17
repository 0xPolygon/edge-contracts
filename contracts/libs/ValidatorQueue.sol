// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IValidatorQueue.sol";
import "../interfaces/IValidator.sol";

/**
 * @title Validator Queue Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice library to manage a queue of updates to block validators
 * including registering a new validator, adding to stake or unstaking,
 * delegation and undelegation
 * @dev queue is processed and cleared at the end of each epoch
 */
library ValidatorQueueLib {
    /**
     * @notice queues a validator's data
     * @param self ValidatorQueue struct
     * @param validator address of the validator
     * @param stake delta to the amount staked by validator (negative for unstaking)
     * @param delegation delta to the amount delegated to validator (negative for undelegating)
     */
    function insert(ValidatorQueue storage self, address validator, int256 stake, int256 delegation) internal {
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
     * @notice deletes data from a specific validator in the queue
     * @dev used in tandem with reset() to delete queue
     * @param self ValidatorQueue struct
     * @param validator address of the validator to remove the queue data of
     */
    function resetIndex(ValidatorQueue storage self, address validator) internal {
        self.indices[validator] = 0;
    }

    /**
     * @notice reinitializes the validator queue
     * @dev used in tandem with resetIndex() to delete queue
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
     * @notice convenience function to return the change to stake for a validator in the queue
     * @param self the ValidatorQueue struct
     * @param validator the address of the validator to check the change to stake of
     * @return int256 change to stake of the validator
     */
    function pendingStake(ValidatorQueue storage self, address validator) internal view returns (int256) {
        if (!waiting(self, validator)) return 0;
        return self.queue[indexOf(self, validator)].stake;
    }

    /**
     * @notice convenience function to return the change to funds delegated to a pending validator
     * @param self the ValidatorQueue struct
     * @param validator the address of the validator to check the change to delegated funds of
     * @return int256 change to funds delegated to the validator
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
        assert(index != 0); // currently index == 0 is unreachable
        return index - 1;
    }
}
