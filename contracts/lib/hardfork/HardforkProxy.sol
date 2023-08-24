// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HPCore.sol";

/**
    @title HardforkProxy
    @author Polygon Technology
    @notice wrapper for OpenZeppelin's Transparent Upgreadable Proxy, intended for use during harfork genesis for genesis contracts
    @notice one HarforkProxy should be deployed for each genesis contract, but there are exceptions - see below
    @dev For ValidatorSet, RewardPool, ForkParams, and NetworkParams, use the respective dedicated HardforkProxy instead
    @dev If starting fresh, use StandardProxy instead
 */
contract HardforkProxy is HPCore {
    /// @notice function for initializing proxy
    /// @param logic the address of the implementation (logic) contract for the genesis contract
    /// @param admin the address that has permission to update what address contains the implementation
    function setUpProxy(address logic, address admin) external {
        _setUpProxy(logic, admin);
    }
}
