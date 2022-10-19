// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICVSAccessControl {
    event AddedToWhitelist(address indexed validator);
    event RemovedFromWhitelist(address indexed validator);

    /**
     * @notice Adds addresses that are allowed to register as validators.
     * @param whitelistAddreses Array of address to whitelist
     */
    function addToWhitelist(address[] calldata whitelistAddreses) external;

    /**
     * @notice Deletes addresses that are allowed to register as validators.
     * @param whitelistAddreses Array of address to remove from whitelist
     */
    function removeFromWhitelist(address[] calldata whitelistAddreses) external;
}
