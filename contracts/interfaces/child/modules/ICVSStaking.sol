// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ICVSStorage.sol";

interface ICVSStaking {
    event NewValidator(address indexed validator, uint256[4] blsKey);
    event CommissionUpdated(address indexed validator, uint256 oldCommission, uint256 newCommission);
    event Staked(address indexed validator, uint256 amount);
    event Unstaked(address indexed validator, uint256 amount);
    event ValidatorRewardClaimed(address indexed validator, uint256 amount);
    event ValidatorRewardDistributed(address indexed validator, uint256 amount);

    /**
     * @notice Validates BLS signature with the provided pubkey and registers validators into the set.
     * @param signature Signature to validate message against
     * @param pubkey BLS public key of validator
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external;

    /**
     * @notice Stakes sent amount. Claims rewards beforehand.
     */
    function stake() external payable;

    /**
     * @notice Unstakes amount for sender. Claims rewards beforehand.
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Sets commission for validator.
     * @param newCommission New commission (100 = 100%)
     */
    function setCommission(uint256 newCommission) external;

    /**
     * @notice Claims validator rewards for sender.
     */
    function claimValidatorReward() external;

    /**
     * @notice Gets first n active validators sorted by total stake.
     * @param n Desired number of validators to return
     * @return Returns array of addresses of first n active validators sorted by total stake,
     * or fewer if there are not enough active validators
     */
    function sortedValidators(uint256 n) external view returns (address[] memory);

    /**
     * @notice Calculates total stake in the network (self-stake + delegation).
     * @return Total stake (in MATIC wei)
     */
    function totalStake() external view returns (uint256);

    /**
     * @notice Gets validator's total stake (self-stake + delegation).
     * @param validator Address of validator
     * @return Validator's total stake (in MATIC wei)
     */
    function totalStakeOf(address validator) external view returns (uint256);

    /**
     * @notice Gets validator's unclaimed rewards.
     * @param validator Address of validator
     * @return Validator's unclaimed rewards (in MATIC wei)
     */
    function getValidatorReward(address validator) external view returns (uint256);
}
