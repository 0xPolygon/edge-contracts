// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
 * @param head earliest unprocessed index
 * (which is also the most recently filled witrhdrawal)
 * @param tail index of most recent withdrawal
 * (which is also the total number of submitted withdrawals)
 * @param withdrawals Withdrawal structs by index
 */
struct WithdrawalQueue {
    uint256 head;
    uint256 tail;
    mapping(uint256 => Withdrawal) withdrawals;
}
