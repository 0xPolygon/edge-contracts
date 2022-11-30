// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICVSAccessControl {
    event SprintUpdated(uint256 oldSprint, uint256 newSprint);
    event AddedToWhitelist(address indexed validator);
    event RemovedFromWhitelist(address indexed validator);

    /**
     * @notice Set the amount of blocks per epoch
     * @param newSprint the new amount of blocks per epoch
     */
    function setSprint(uint256 newSprint) external;

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
