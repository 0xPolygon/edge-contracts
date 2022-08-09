// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "contracts/common/Owned.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";

contract OwnedTest is TestPlus {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed proposedOwner);

    OwnedMock ownedMock;

    function setUp() public {
        ownedMock = new OwnedMock();
    }

    function testInitializer() public {
        assertEq(ownedMock.owner(), address(this));
        assertEq(ownedMock.proposedOwner(), address(0));
    }

    function testCannotProposeOwner_Unauthorized() public {
        vm.startPrank(makeAddr("notOwner"));
        address payable proposedOwner = payable(makeAddr("proposedOwner"));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "OWNER"));
        ownedMock.proposeOwner(proposedOwner);
    }

    function testProposeOwner() public {
        address payable proposedOwner = payable(makeAddr("proposedOwner"));

        vm.expectEmit(true, false, false, false);
        emit OwnershipProposed(proposedOwner);
        ownedMock.proposeOwner(proposedOwner);
        assertEq(ownedMock.proposedOwner(), proposedOwner);
    }

    function testCannotClaimOwnership_Unauthorized() public {
        address payable proposedOwner = payable(makeAddr("proposedOwner"));
        ownedMock.proposeOwner(proposedOwner);
        vm.startPrank(makeAddr("notProposedOwner"));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "PROPOSED_OWNER"));
        ownedMock.claimOwnership();
    }

    function testClaimOwnership() public {
        address payable proposedOwner = payable(makeAddr("proposedOwner"));
        ownedMock.proposeOwner(proposedOwner);
        vm.startPrank(proposedOwner);

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(this), proposedOwner);
        ownedMock.claimOwnership();
        assertEq(ownedMock.owner(), proposedOwner);
    }
}

contract OwnedMock is Owned {
    constructor() {
        __Owned_init();
    }
}
