// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Validator} from "../interfaces/IValidator.sol";
import "./ChildValidatorSet/ICVSStorage.sol";

/**
 * @title ChildValidatorSet
 * @author Polygon Technology
 * @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
 * @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 * It manages staking, epoch committing, and reward distribution.
 */
interface IChildValidatorSet {
    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);
    event NewValidator(address indexed validator, uint256[4] blsKey);
    event AddedToWhitelist(address indexed validator);
    event RemovedFromWhitelist(address indexed validator);
    event Staked(address indexed validator, uint256 amount);
    event Unstaked(address indexed validator, uint256 amount);
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);
    event Undelegated(address indexed delegator, address indexed validator, uint256 amount);
    event ValidatorRewardClaimed(address indexed validator, uint256 amount);
    event DelegatorRewardClaimed(
        address indexed delegator,
        address indexed validator,
        bool indexed restake,
        uint256 amount
    );
    event WithdrawalRegistered(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, address indexed to, uint256 amount);
    event ValidatorRewardDistributed(address indexed validator, uint256 amount);
    event DelegatorRewardDistributed(address indexed validator, uint256 amount);

    error StakeRequirement(string src, string msg);

    /**
     * @notice Allows the v3 client to commit epochs to this contract.
     * @param id ID of epoch to be committed
     * @param epoch Epoch data to be committed
     * @param uptime Uptime data for the epoch being committed
     */
    function commitEpoch(
        uint256 id,
        Epoch calldata epoch,
        Uptime calldata uptime
    ) external;

    /**
     * @notice Gets addresses of active validators in this epoch, sorted by total stake (self-stake + delegation)
     * @return Array of addresses of active validators in this epoch, sorted by total stake
     */
    function getCurrentValidatorSet() external view returns (address[] memory);

    /**
     * @notice Look up an epoch by block number. Searches in O(log n) time.
     * @param blockNumber ID of epoch to be committed
     * @return Epoch Returns epoch if found, or else, the last epoch
     */
    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory);

    /**
     * @notice Adds addresses that are allowed to register as validators.
     * @param whitelistAddreses Array of address to whitelist
     */
    function addToWhitelist(address[] calldata whitelistAddreses) external;

    /**
     * @notice Deletes addresses that are allowed to register as validators.
     * @param whitelistAddreses Array of address to remove from whitelist
     */
    function removeFromWhitelist(address[] calldata whitelistAddreses) external;

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
     * @notice Withdraws sender's withdrawable amount to specified address.
     * @param to Address to withdraw to
     */
    function withdraw(address to) external;

    /**
     * @notice Claims validator rewards for sender.
     */
    function claimValidatorReward() external;

    /**
     * @notice Claims delegator rewards for sender.
     * @param validator Validator to claim from
     * @param restake Whether to redelegate the claimed rewards
     */
    function claimDelegatorReward(address validator, bool restake) external;

    /**
     * @notice Sets commission for validator.
     * @param newCommission New commission (100 = 100%)
     */
    function setCommission(uint256 newCommission) external;

    /**
     * @notice Gets validator by address.
     * @return Validator (BLS public key, self-stake, total stake, commission, withdrawable rewards, activity status)
     */
    function getValidator(address validator) external view returns (Validator memory);

    /**
     * @notice Gets amount delegated by delegator to validator.
     * @param validator Address of validator
     * @param delegator Address of delegator
     * @return Amount delegated (in MATIC wei)
     */
    function delegationOf(address validator, address delegator) external view returns (uint256);

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
     * @notice Calculates total stake of active validators (self-stake + delegation).
     * @return Total stake of active validators (in MATIC wei)
     */
    function totalActiveStake() external view returns (uint256);

    /**
     * @notice Calculates how much can be withdrawn for account in this epoch.
     * @param account The account to calculate amount for
     * @return Amount withdrawable (in MATIC wei)
     */
    function withdrawable(address account) external view returns (uint256);

    /**
     * @notice Calculates how much is yet to become withdrawable for account.
     * @param account The account to calculate amount for
     * @return Amount not yet withdrawable (in MATIC wei)
     */
    function pendingWithdrawals(address account) external view returns (uint256);

    /**
     * @notice Gets validator's unclaimed rewards.
     * @param validator Address of validator
     * @return Validator's unclaimed rewards (in MATIC wei)
     */
    function getValidatorReward(address validator) external view returns (uint256);

    /**
     * @notice Gets delegators's unclaimed rewards with validator.
     * @param validator Address of validator
     * @param delegator Address of delegator
     * @return Delegator's unclaimed rewards with validator (in MATIC wei)
     */
    function getDelegatorReward(address validator, address delegator) external view returns (uint256);
}
