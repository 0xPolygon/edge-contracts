// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISupernetManager {
    /// @notice called when a new child chain is registered
    function onInit(uint256 id) external;

    /// @notice called when a validator stakes
    function onStake(address validator, uint256 amount, bytes calldata data) external;
}
