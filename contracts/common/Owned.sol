// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/IOwned.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Owned is IOwned, Initializable {
    address public owner;
    address public proposedOwner;

    /// @dev initializes the contract setting the deployer as the initial owner
    // solhint-disable-next-line func-name-mixedcase
    function __Owned_init() internal initializer {
        _transferOwnership(msg.sender);
    }

    /// @dev throws if called by any account other than the owner
    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized("OWNER");
        _;
    }

    /// @dev can only be called by the new current owner
    function proposeOwner(address payable _newOwner) external virtual onlyOwner {
        proposedOwner = _newOwner;
        emit OwnershipProposed(_newOwner);
    }

    /// @dev can only be called by the new proposed owner
    function claimOwnership() external virtual {
        if (msg.sender != proposedOwner) revert Unauthorized("PROPOSED_OWNER");
        _transferOwnership(proposedOwner);
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
