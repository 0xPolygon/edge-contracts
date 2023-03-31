// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../IStateReceiver.sol";
import "../../../child/modules/CVSWithdrawal.sol";

struct ValidatorInit {
    address addr;
    uint256 stake;
}

interface IValidatorSet is IStateReceiver {
    /// @notice amount of blocks in an epoch
    /// @dev when an epoch is committed a multiple of this number of blocks must be committed
    function EPOCH_SIZE() external view returns (uint256);

    /// @notice total amount of blocks in a given epoch
    function totalBlocks(uint256 epochId) external view returns (uint256 length);

    /// @notice returns a validator balance for a given epoch
    function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256);

    /// @notice returns the total supply for a given epoch
    function totalSupplyAt(uint256 epochNumber) external view returns (uint256);

    /// @notice commits a new epoch
    /// @dev system call
    function commitEpoch(uint256 id, Epoch calldata epoch) external;

    /// @notice allows a validator to announce their intention to withdraw a given amount of tokens
    /// @dev initializes a waiting period before the tokens can be withdrawn
    function unstake(uint256 amount) external;

    /// @notice allows a validator to complete a withdrawal
    /// @dev calls the bridge to release the funds on root
    function withdraw() external;
}
