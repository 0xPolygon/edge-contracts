// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IValidatorSet.sol";

interface IRewardDistributor {
    /// @notice distributes reward for the given epoch
    /// @dev transfers funds from sender to this contract
    /// @param epochId epoch id to distribute rewards for
    /// @param uptime uptime data for every validator
    function distributeRewardFor(uint256 epochId, Uptime calldata uptime) external;

    /// @notice withdraws pending rewards for the sender (validator)
    function withdrawReward() external;

    /// @notice returns the total reward paid for the given epoch
    function paidRewardPerEpoch(uint256 epochId) external view returns (uint256);

    /// @notice returns the pending reward for the given account
    function pendingRewards(address account) external view returns (uint256);
}
