// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOwned {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed proposedOwner);

    /**
     * @notice proposes a new owner (step 1 of transferring ownership)
     * @dev can only be called by the current owner
     * @param _newOwner address of new proposed owner
     */
    function proposeOwner(address payable _newOwner) external;

    /**
     * @notice allows proposed owner to claim ownership (step 2 of transferring ownership)
     * @dev can only be called by the new proposed owner
     */
    function claimOwnership() external;
}
