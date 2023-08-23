// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
    @title BasicGenesisProxy
    @author Polygon Technology
    @notice wrapper for OpenZeppelin's Transparent Upgreadable Proxy, intended for use during genesis for genesis contracts
    @notice one BasicGenesisProxy should be deployed for each genesis contract
    @dev If hardforking, use BasicHFGenesisProxy & the contract-specific proxies instead
 */
contract BasicGenesisProxy is TransparentUpgradeableProxy {
    /// @param logic the address of the implementation (logic) contract for the genesis contract
    /// @param admin the address that has permission to update what address contains the implementation
    /// @param data raw calldata for the intialization of the genesis contract's implementation
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) {}
}
