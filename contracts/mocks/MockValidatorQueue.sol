// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libs/ValidatorQueue.sol";

contract MockValidatorQueue {
    using ValidatorQueueLib for ValidatorQueue;

    ValidatorQueue queue;

    function stake(
        address validator,
        uint256 _stake,
        uint256 _delegation
    ) public {
        queue.insert(validator, int256(_stake), int256(_delegation));
    }

    function unstake(
        address validator,
        uint256 _stake,
        uint256 _delegation
    ) public {
        queue.insert(validator, int256(_stake) * -1, int256(_delegation) * -1);
    }

    function reset() public {
        queue.reset();
    }

    function getQueue() public view returns (QueuedValidator[] memory) {
        return queue.get();
    }

    function getIndex(address validator) public view returns (uint256 index) {
        return queue.indices[validator];
    }
}
