// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Validator} from "../interfaces/IValidator.sol";

struct UptimeData {
    address validator;
    uint256 signedBlocks;
}

struct Uptime {
    uint256 epochId;
    UptimeData[] uptimeData;
    uint256 totalBlocks;
}

struct Stake {
    uint256 epochId;
    uint256 amount;
}

// enum ValidatorStatus {
//     REGISTERED, // 0 -> will be staked next epock
//     STAKED, // 1 -> currently staked (i.e. validating)
//     UNSTAKING, // 2 -> currently unstaking (i.e. will stop validating)
//     UNSTAKED // 3 -> not staked (i.e. is not validating)
// }

struct Epoch {
    uint256 startBlock;
    uint256 endBlock;
    bytes32 epochRoot;
}

/// @title ChildValidatorSet
/// @author Polygon Technology
/// @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
/// @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
interface IChildValidatorSet {
    // TODO events
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

    /// @notice Allows the v3 client to commit epochs to this contract.
    /// @param id ID of epoch to be committed
    /// @param epoch New epoch data to be committed
    /// @param uptime Uptime data for the epoch being committed
    function commitEpoch(
        uint256 id,
        Epoch calldata epoch,
        Uptime calldata uptime
    ) external;

    function getCurrentValidatorSet() external view returns (address[] memory);

    /// @notice Look up an epoch by block number. Searches in O(log n) time.
    /// @param blockNumber ID of epoch to be committed
    /// @return Epoch Returns epoch if found, or else, the last epoch
    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory);

    /// @notice Adds addresses which are allowed to register as validators.
    /// @param whitelistAddreses Array of address to whitelist
    function addToWhitelist(address[] calldata whitelistAddreses) external;

    /// @notice Deletes addresses which are allowed to register as validators.
    /// @param whitelistAddreses Array of address to remove from whitelist
    function removeFromWhitelist(address[] calldata whitelistAddreses) external;

    /// @notice Validates BLS signature with the provided pubkey and registers validators into the set.
    /// @param signature Signature to validate message against
    /// @param pubkey BLS public key of validator
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external;

    function stake() external payable;

    function unstake(uint256 amount) external;

    function delegate(address validator, bool restake) external payable;

    function undelegate(address validator, uint256 amount) external;

    function withdraw(address to) external;

    function claimValidatorReward() external;

    function claimDelegatorReward(address validator, bool restake) external;

    function setCommission(uint256 newCommission) external;

    function getValidator(address validator) external view returns (Validator memory);

    // get first `n` of validators sorted by stake from high to low
    function sortedValidators(uint256 n) external view returns (address[] memory);

    /// @notice Calculate total stake in the network (self-stake + delegation)
    /// @return stake Returns total stake (in MATIC wei)
    function totalStake() external view returns (uint256);

    function totalActiveStake() external view returns (uint256);

    function withdrawable(address account) external view returns (uint256);

    function pendingWithdrawals(address account) external view returns (uint256);

    function getValidatorReward(address validator) external view returns (uint256);

    function getDelegatorReward(address validator, address delegator) external view returns (uint256);
}
