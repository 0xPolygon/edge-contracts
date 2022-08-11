// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "contracts/common/Owned.sol";
import {MockOwned} from "contracts/mocks/MockOwner.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";

contract OwnedTest is TestPlus {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed proposedOwner);

    MockOwned mockOwned;

    function setUp() public {
        mockOwned = new MockOwned();
        mockOwned.initialize();
    }

    function testInitializer() public {
        assertEq(mockOwned.owner(), address(this));
        assertEq(mockOwned.proposedOwner(), address(0));
    }

    function testCannotProposeOwner_Unauthorized() public {
        vm.startPrank(makeAddr("notOwner"));
        address payable proposedOwner = payable(makeAddr("proposedOwner"));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "OWNER"));
        mockOwned.proposeOwner(proposedOwner);
    }

    function testProposeOwner() public {
        address payable proposedOwner = payable(makeAddr("proposedOwner"));

        // event
        vm.expectEmit(true, false, false, false);
        emit OwnershipProposed(proposedOwner);
        mockOwned.proposeOwner(proposedOwner);
        // proposed owner
        assertEq(mockOwned.proposedOwner(), proposedOwner);
    }

    function testCannotClaimOwnership_Unauthorized() public {
        address payable proposedOwner = payable(makeAddr("proposedOwner"));
        mockOwned.proposeOwner(proposedOwner);
        vm.startPrank(makeAddr("notProposedOwner"));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "PROPOSED_OWNER"));
        mockOwned.claimOwnership();
    }

    function testClaimOwnership() public {
        address payable proposedOwner = payable(makeAddr("proposedOwner"));
        mockOwned.proposeOwner(proposedOwner);
        vm.startPrank(proposedOwner);

        // event
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(this), proposedOwner);
        mockOwned.claimOwnership();
        // owner
        assertEq(mockOwned.owner(), proposedOwner);
    }
}
