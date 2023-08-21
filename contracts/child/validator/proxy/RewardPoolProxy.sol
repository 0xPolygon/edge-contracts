// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/GenesisProxy.sol";

contract RewardPoolProxy is GenesisProxy {
    /// @notice function for initializing proxy for the RewardPool genesis contract
    /// @dev meant to be deployed during genesis
    /// @dev in the case of migration, the newNetworkParams arg should point to the new NetworkParams
    /// @param logic the address of the implementation (logic) contract for the reward pool
    /// @param admin the address that has permission to update what address contains the implementation
    /// @param data raw calldata for the intialization of the RewardPool implementation
    /// @param newNetworkParams address of genesis contract NetworkParams
    function setUpProxy(address logic, address admin, bytes memory data, address newNetworkParams) external {
        _setUpProxy(logic, admin, data);

        // this writes the address of NetworkParams to storage
        // this is performed in assembly for contracts migrating from not being proxified
        // slither-disable-next-line assembly
        assembly {
            sstore(56, newNetworkParams)
        }
    }
}
