// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/hardfork/HFGenesisProxy.sol";

/// @notice RewardPool-specific proxy for hardfork migration
/// @dev If starting fresh, use BasicGenesisProxy instead
contract RewardPoolHFGenesisProxy is HFGenesisProxy {
    /// @notice function for initializing proxy for the RewardPool genesis contract
    /// @dev meant to be deployed during genesis
    /// @param logic the address of the implementation (logic) contract for the reward pool
    /// @param admin the address that has permission to update what address contains the implementation
    /// @param newNetworkParams address of genesis contract NetworkParams
    function setUpProxy(address logic, address admin, address newNetworkParams) external {
        _setUpProxy(logic, admin);

        // this writes the address of NetworkParams to storage
        // this is performed in assembly for contracts migrating from not being proxified
        // slither-disable-next-line assembly
        assembly {
            sstore(56, newNetworkParams)
        }
    }
}
