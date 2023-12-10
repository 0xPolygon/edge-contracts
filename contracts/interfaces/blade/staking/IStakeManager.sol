// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Validator {
    address addr;
    uint256[4] blsKey;
    bool isWhitelisted;
    bool isActive;
}

struct GenesisValidator {
    address addr;
    uint256 stake;
    uint256[4] blsKey;
}

/**
    @title IStakeManager
    @author Polygon Technology (@gretzke)
    @notice Manages stakes for all child chains
 */
interface IStakeManager {
    event StakeAdded(address indexed validator, uint256 amount);
    event StakeRemoved(address indexed validator, uint256 amount);
    event AddedToWhitelist(address indexed validator);
    event RemovedFromWhitelist(address indexed validator);
    event ValidatorRegistered(address indexed validator, uint256[4] blsKey, uint256 amount);
    event ValidatorDeactivated(address indexed validator);
    event StakeWithdrawn(address indexed account, uint256 amount);

    error Unauthorized(string message);
    error InvalidSignature(address validator);

    /// @notice called by a validator to stake for a child chain
    function stake(uint256 amount) external;

    /// @notice called by a validator to unstake
    function unstake(uint256 amount) external;

    /// @notice returns the total amount staked for all child chains
    function totalStake() external view returns (uint256 amount);

    /// @notice returns the amount staked by a validator for a child chain
    function stakeOf(address validator) external view returns (uint256 amount);

    function whitelistValidators(address[] calldata validators_) external;

    function register(uint256[2] calldata signature, uint256[4] calldata pubkey, uint256 stakeAmount) external;

    function getValidator(address validator_) external view returns (Validator memory);

    /// @notice allows a validator to complete a withdrawal
    /// @dev calls the bridge to release the funds on root
    function withdraw() external;

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

    /// @notice returns the total supply for a given epoch
    function totalSupplyAt(uint256 epochNumber) external view returns (uint256);

    /// @notice returns a validator balance for a given epoch
    function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256);
}
