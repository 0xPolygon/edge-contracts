// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HFGenesisProxy.sol";

/**
    @title BasicHFGenesisProxy
    @author Polygon Technology
    @notice wrapper for OpenZeppelin's Transparent Upgreadable Proxy, intended for use during harfork genesis for genesis contracts
    @notice one BasicHFGenesisProxy should be deployed for each genesis contract
    @dev For ValidatorSet, RewardPool, ForkParams, and NetworkParams, use their dedicated proxies instead
    @dev If starting fresh, use BasicGenesisProxy instead
 */
contract BasicHFGenesisProxy is HFGenesisProxy {
    /// @notice function for initializing proxy
    /// @param logic the address of the implementation (logic) contract for the genesis contract
    /// @param admin the address that has permission to update what address contains the implementation
    function setUpProxy(address logic, address admin) external {
        _setUpProxy(logic, admin);
    }
}
