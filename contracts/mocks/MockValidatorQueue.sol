// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/ValidatorQueue.sol";

contract MockValidatorQueue {
    using ValidatorQueueLib for ValidatorQueue;

    ValidatorQueue queue;

    function stake(address validator, uint256 stake_, uint256 delegation) external {
        queue.insert(validator, int256(stake_), int256(delegation));
    }

    function unstake(address validator, uint256 stake_, uint256 delegation) external {
        queue.insert(validator, int256(stake_) * -1, int256(delegation) * -1);
    }

    function reset() external {
        queue.reset();
    }

    function getQueue() external view returns (QueuedValidator[] memory) {
        return queue.get();
    }

    function getIndex(address validator) external view returns (uint256 index) {
        return queue.indices[validator];
    }
}
