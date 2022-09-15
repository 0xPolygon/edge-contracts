// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Errors.sol";

interface IOwned {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed proposedOwner);

    /// @notice propeses a new owner
    /// @param _newOwner address of new proposed owner
    function proposeOwner(address payable _newOwner) external;

    /// @notice claim ownership of the contract
    function claimOwnership() external;
}
