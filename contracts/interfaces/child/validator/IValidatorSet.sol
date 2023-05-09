// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../IStateReceiver.sol";

struct ValidatorInit {
    address addr;
    uint256 stake;
}

struct Epoch {
    uint256 startBlock;
    uint256 endBlock;
    bytes32 epochRoot;
}

/**
    @title IValidatorSet
    @author Polygon Technology (@gretzke)
    @notice Manages voting power for validators and commits epochs for child chains
    @dev Voting power is synced between the stake manager on root on stake and unstake actions
 */
interface IValidatorSet is IStateReceiver {
    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);
    event Slashed(uint256 indexed validator, uint256 amount);
    event WithdrawalRegistered(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    /// @notice commits a new epoch
    /// @dev system call
    function commitEpoch(uint256 id, Epoch calldata epoch) external;

    /// @notice allows a validator to announce their intention to withdraw a given amount of tokens
    /// @dev initializes a waiting period before the tokens can be withdrawn
    function unstake(uint256 amount) external;

    /// @notice allows a validator to complete a withdrawal
    /// @dev calls the bridge to release the funds on root
    function withdraw() external;

    /// @notice amount of blocks in an epoch
    /// @dev when an epoch is committed a multiple of this number of blocks must be committed
    // slither-disable-next-line naming-convention
    function EPOCH_SIZE() external view returns (uint256);

    /// @notice total amount of blocks in a given epoch
    function totalBlocks(uint256 epochId) external view returns (uint256 length);

    /// @notice returns a validator balance for a given epoch
    function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256);

    /// @notice returns the total supply for a given epoch
    function totalSupplyAt(uint256 epochNumber) external view returns (uint256);

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
}
