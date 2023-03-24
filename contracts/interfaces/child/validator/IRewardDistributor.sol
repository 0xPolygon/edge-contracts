// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IValidatorSet.sol";

interface RewardToken is IERC20 {
    function mintRewards(uint256 amount) external;
}

interface IRewardDistributor {
    function distributeRewardFor(uint256 epochId, Uptime calldata uptime) external;

    function withdrawReward() external;

    function paidRewardPerEpoch(uint256 epochId) external view returns (uint256);

    function pendingRewards(address account) external view returns (uint256);
}
