// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyBase.sol";

/**
    @title GenesisProxy
    @author Polygon Technology
    @notice wrapper for OpenZeppelin's Transparent Upgreadable Proxy, intended for use during genesis for genesis contracts
    @notice one GenesisProxy should be deployed for each genesis contract, but there are exceptions if hardforking - see below
    @dev If hardforking, for ValidatorSet, RewardPool, ForkParams, and NetworkParams, use the respective dedicated HardforkProxy instead
 */
contract GenesisProxy is ProxyBase {
    /// @notice function for initializing proxy
    /// @param logic the address of the implementation (logic) contract for the genesis contract
    /// @param admin the address that has permission to update what address contains the implementation
    /// @param data raw calldata for the intialization of the genesis contract (if required)
    function setUpProxy(address logic, address admin, bytes memory data) external {
        _setUpProxy(logic, admin, data);
    }
}
