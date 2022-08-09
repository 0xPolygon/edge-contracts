// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/IOwned.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Owned is IOwned, Initializable {
    address public owner;
    address public proposedOwner;

    /// @dev initializes the contract setting the deployer as the initial owner
    function __Owned_init() internal onlyInitializing {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @dev throws if called by any account other than the owner
    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized("OWNER");
        _;
    }

    /// @dev can only be called by the new current owner
    function proposeOwner(address payable _newOwner) external onlyOwner {
        proposedOwner = _newOwner;
        emit OwnershipProposed(_newOwner);
    }

    /// @dev can only be called by the new proposed owner
    function claimOwnership() external {
        if (msg.sender != proposedOwner) revert Unauthorized("PROPOSED_OWNER");
        emit OwnershipTransferred(owner, proposedOwner);
        owner = proposedOwner;
    }
}
