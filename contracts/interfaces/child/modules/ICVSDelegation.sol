// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ICVSStorage.sol";

interface ICVSDelegation {
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);
    event Undelegated(address indexed delegator, address indexed validator, uint256 amount);
    event DelegatorRewardClaimed(
        address indexed delegator,
        address indexed validator,
        bool indexed restake,
        uint256 amount
    );
    event DelegatorRewardDistributed(address indexed validator, uint256 amount);

    /**
     * @notice Delegates sent amount to validator. Claims rewards beforehand.
     * @param validator Validator to delegate to
     * @param restake Whether to redelegate the claimed rewards
     */
    function delegate(address validator, bool restake) external payable;

    /**
     * @notice Undelegates amount from validator for sender. Claims rewards beforehand.
     * @param validator Validator to undelegate from
     * @param amount The amount to undelegate
     */
    function undelegate(address validator, uint256 amount) external;

    /**
     * @notice Claims delegator rewards for sender.
     * @param validator Validator to claim from
     * @param restake Whether to redelegate the claimed rewards
     */
    function claimDelegatorReward(address validator, bool restake) external;

    /**
     * @notice Gets the total amount delegated to a validator.
     * @param validator Address of validator
     * @return Amount delegated (in MATIC wei)
     */
    function totalDelegationOf(address validator) external view returns (uint256);

    /**
     * @notice Gets amount delegated by delegator to validator.
     * @param validator Address of validator
     * @param delegator Address of delegator
     * @return Amount delegated (in MATIC wei)
     */
    function delegationOf(address validator, address delegator) external view returns (uint256);

    /**
     * @notice Gets delegators's unclaimed rewards with validator.
     * @param validator Address of validator
     * @param delegator Address of delegator
     * @return Delegator's unclaimed rewards with validator (in MATIC wei)
     */
    function getDelegatorReward(address validator, address delegator) external view returns (uint256);
}
