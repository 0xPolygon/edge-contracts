// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../interfaces/root/staking/ISupernetManager.sol";

/**
    @title IStakeManager
    @author Polygon Technology (@gretzke)
    @notice Manages stakes for all child chains
 */
interface IStakeManager {
    event ChildManagerRegistered(uint256 indexed id, address indexed manager);
    event StakeAdded(uint256 indexed id, address indexed validator, uint256 amount);
    event StakeRemoved(uint256 indexed id, address indexed validator, uint256 amount);
    event StakeWithdrawn(address indexed validator, address indexed recipient, uint256 amount);

    /// @notice registers a new child chain with the staking contract
    /// @return id of the child chain
    function registerChildChain(address manager) external returns (uint256 id);

    /// @notice called by a validator to stake for a child chain
    function stakeFor(uint256 id, uint256 amount) external;

    /// @notice called by child manager contract to release a validator's stake
    function releaseStakeOf(address validator, uint256 amount) external;

    /// @notice allows a validator to withdraw released stake
    function withdrawStake(address to, uint256 amount) external;

    /// @notice returns the amount of stake a validator can withdraw
    function withdrawableStake(address validator) external view returns (uint256 amount);

    /// @notice returns the total amount staked for all child chains
    function totalStake() external view returns (uint256 amount);

    /// @notice returns the total amount staked for a child chain
    function totalStakeOfChild(uint256 id) external view returns (uint256 amount);

    /// @notice returns the total amount staked of a validator for all child chains
    function totalStakeOf(address validator) external view returns (uint256 amount);

    /// @notice returns the amount staked by a validator for a child chain
    function stakeOf(address validator, uint256 id) external view returns (uint256 amount);

    /// @notice returns the child chain manager contract for a child chain
    function managerOf(uint256 id) external view returns (ISupernetManager manager);

    /// @notice returns the child id for a child chain manager contract
    function idFor(address manager) external view returns (uint256 id);
}
