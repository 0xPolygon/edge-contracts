// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IOwned.sol";

import "../interfaces/Errors.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Owned
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice single address access control with a two-step transfer
 */
abstract contract Owned is IOwned, Initializable {
    /**
     * @notice the address of the owner
     * @return address
     */
    address public owner;
    /**
     * @notice the address of a proposed owner
     * @dev the proposed owner can transfer ownership to themselves
     * @return address
     */
    address public proposedOwner;

    /**
     * @notice initializes the contract setting the deployer as the initial owner
     * @dev modifier is in OpenZeppelin's contracts-upgradeable
     */
    // prettier-ignore
    // slither-disable-next-line naming-convention
    function __Owned_init() internal onlyInitializing { // solhint-disable-line func-name-mixedcase
        _transferOwnership(msg.sender);
    }

    /**
     * @notice limits access of a function to the owner
     */
    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized("OWNER");
        _;
    }

    /**
     * @inheritdoc IOwned
     */
    // slither-disable-next-line missing-zero-check
    function proposeOwner(address payable newOwner) external virtual onlyOwner {
        proposedOwner = newOwner;
        emit OwnershipProposed(newOwner);
    }

    /**
     * @inheritdoc IOwned
     */
    function claimOwnership() external virtual {
        if (msg.sender != proposedOwner) revert Unauthorized("PROPOSED_OWNER");
        _transferOwnership(proposedOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
