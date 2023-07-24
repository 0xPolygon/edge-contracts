// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Flow Rate Detection
 * @author Immutable Pty Ltf (Peter Robinson @drinkcoffee and Zhenyang Shi wcgcyx)
 * @notice Detects large flows of tokens using a bucket system.
 * @dev    Each token has a bucket. The bucket is filled at a constant rate: a number of
 *         tokens per second. The bucket empties each time there is a withdrawal. Withdrawal
 *         requests for tokens that don't have a configured bucket are delayed.
 *         Note: This code is part of RootERC20PredicateFlowRate. It has been separated out
 *         to make it easier to understand the functionality.
 *         Note that this contract is upgradeable.
 */
abstract contract FlowRateDetection {
    // Holds flow rate information for a single token.
    struct Bucket {
        // The number of tokens that can fit in the bucket.
        // A capacity of zero indicates that flow rate detection is disabled for the token.
        uint256 capacity;
        // The number of tokens in the bucket.
        uint256 depth;
        // The last time the bucket was updated.
        uint256 refillTime;
        // The number of tokens added per second.
        uint256 refillRate;
    }

    // Map ERC 20 token address to buckets
    mapping(address => Bucket) public flowRateBuckets;

    // True if all tokens should be put in the withdrawal queue.
    bool public withdrawalQueueActivated;

    // Emitted when there is a withdrawal request for a token for which there is no bucket.
    event WithdrawalForNonFlowRatedToken(address indexed token, uint256 amount);
    // Emitted when queue activated or deactivated
    event AutoActivatedWithdrawalQueue();
    event ActivatedWithdrawalQueue(address who);
    event DeactivatedWithdrawalQueue(address who);

    /**
     * @notice Activate the withdrawal queue for all tokens.
     */
    function _activateWithdrawalQueue() internal {
        withdrawalQueueActivated = true;
        emit ActivatedWithdrawalQueue(msg.sender);
    }

    /**
     * @notice Deactivate the withdrawal queue for all tokens.
     */
    function _deactivateWithdrawalQueue() internal {
        withdrawalQueueActivated = false;
        emit DeactivatedWithdrawalQueue(msg.sender);
    }

    /**
     * @notice Initialise or update a bucket for a token.
     * @param token Address of the token to configure the bucket for.
     * @param capacity The number of tokens before the bucket overflows.
     * @param refillRate The number of tokens added to the bucket each second.
     */
    function _setFlowRateThreshold(address token, uint256 capacity, uint256 refillRate) internal {
        require(token != address(0), "FlowRate:Invalid token address");
        require(capacity != 0, "FlowRate:Capacity must be > 0");
        require(refillRate != 0, "FlowRate:RefillRate must be > 0");
        Bucket storage bucket = flowRateBuckets[token];
        bucket.capacity = capacity;
        bucket.refillRate = refillRate;
    }

    /**
     * @notice Update the flow rate measurement for a token.
     * @param token Address of token being withdrawn.
     * @param amount The number of tokens being withdrawn.
     * @return delayWithdrawal Delay this withdrawal because it is for an unconfigured token.
     */
    function _updateFlowRateBucket(address token, uint256 amount) internal returns (bool delayWithdrawal) {
        Bucket storage bucket = flowRateBuckets[token];

        uint256 capacity = bucket.capacity;
        if (capacity == 0) {
            emit WithdrawalForNonFlowRatedToken(token, amount);
            return true;
        }

        // Calculate the depth assuming no withdrawal. The special case of refill time
        // being 0, as it is when a token is first rate controlled, with result in the
        // depth being set to the capacity of the bucket.
        // solhint-disable-next-line not-rely-on-time
        uint256 depth = bucket.depth + (block.timestamp - bucket.refillTime) * bucket.refillRate;
        // solhint-disable-next-line not-rely-on-time
        bucket.refillTime = block.timestamp;
        if (depth > capacity) {
            depth = capacity;
        }

        if (amount >= depth) {
            // The bucket is empty indicating the flow rate is high. Automatically
            // enable the withdrawal queue.
            emit AutoActivatedWithdrawalQueue();
            withdrawalQueueActivated = true;
            bucket.depth = 0;
        } else {
            bucket.depth = depth - amount;
        }
        return false;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
