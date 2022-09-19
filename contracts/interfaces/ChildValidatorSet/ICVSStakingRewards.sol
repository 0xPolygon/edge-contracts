// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICVSStakingRewards {
    event ValidatorRewardClaimed(address indexed validator, uint256 amount);
    event ValidatorRewardDistributed(address indexed validator, uint256 amount);

    /**
     * @notice Claims validator rewards for sender.
     */
    function claimValidatorReward() external;

    /**
     * @notice Gets validator's unclaimed rewards.
     * @param validator Address of validator
     * @return Validator's unclaimed rewards (in MATIC wei)
     */
    function getValidatorReward(address validator) external view returns (uint256);
}
