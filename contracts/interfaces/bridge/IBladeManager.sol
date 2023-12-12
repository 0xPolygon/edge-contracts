// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../lib/GenesisLib.sol";

/**
    @title IBladeManager
    @notice Manages genesis of a blade chan when bridge is enabled
 */
interface IBladeManager {
    event GenesisBalanceAdded(address indexed account, uint256 indexed amount);
    event GenesisFinalized(uint256 amountValidators);

    error Unauthorized(string message);

    /// @notice initialize is used to initialize the contract with specific data.
    /// @param newRootERC20Predicate represents the address of a root erc20 predicate.
    /// @param genesisValidators represents the genesis validator set on a Blade chain.
    function initialize(address newRootERC20Predicate, GenesisAccount[] calldata genesisValidators) external;

    /// GenesisAccounts initial genesis validator set
    /// @dev only callable by owner
    function finalizeGenesis() external;

    /// @notice returns the genesis validator set with their balances
    function genesisSet() external view returns (GenesisAccount[] memory);

    /// @notice addGenesisBalance is used to specGenesisAccountnce information for genesis accounts on a  Blade chain.
    /// It is applicable only in case Blade native contract is mapped to a pre-existing rootchain ERC20 token.
    /// @param nonStakeAmount represents the amount to be premined in the genesis which is not staked.
    /// @param stakeAmount represents the amount to be premined in genesis which is going to be staked.
    function addGenesisBalance(uint256 nonStakeAmount, uint256 stakeAmount) external;
}
