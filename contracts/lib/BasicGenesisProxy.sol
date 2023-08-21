// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenesisProxy.sol";

/**
    @title BasicGenesisProxy
    @author Polygon Technology
    @notice wrapper for OpenZeppelin's Transparent Upgreadable Proxy, intended for use during genesis for genesis contracts
    @notice one BasicGenesisProxy should be deployed for each genesis contract
 */

contract BasicGenesisProxy is GenesisProxy {
    /// @notice initialization function, sets addresses in proxy and sends initialization payload to implementation
    /// @param logic the address of the implementation (logic) contract for the genesis contract
    /// @param admin the address that has permission to update what address contains the implementation
    /// @param data raw calldata for the intialization of the genesis contract's implementation
    function setUpProxy(address logic, address admin, bytes memory data) external {
        _setUpProxy(logic, admin, data);
    }
}
