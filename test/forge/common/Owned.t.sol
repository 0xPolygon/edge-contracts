// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "contracts/common/Owned.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";

abstract contract InitializedState is TestPlus {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed proposedOwner);

    OwnedMock ownedMock;

    address alien;
    address payable owner;

    function setUp() public virtual {
        ownedMock = new OwnedMock();
        ownedMock.initialize();

        alien = makeAddr("alien");
        owner = payable(makeAddr("owner"));
    }
}

contract OwnedTest_InitializedState is InitializedState {
    function testInitializer() public {
        assertEq(ownedMock.owner(), address(this));
        assertEq(ownedMock.proposedOwner(), address(0));
    }

    function testCannotProposeOwner_Unauthorized() public {
        vm.startPrank(alien);

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "OWNER"));
        ownedMock.proposeOwner(owner);
    }

    function testProposeOwner() public {
        // event
        vm.expectEmit(true, false, false, false);
        emit OwnershipProposed(owner);
        ownedMock.proposeOwner(owner);
        // proposed owner
        assertEq(ownedMock.proposedOwner(), owner);
    }
}

abstract contract ProposedState is InitializedState {
    function setUp() public override {
        super.setUp();
        ownedMock.proposeOwner(owner);
    }
}

contract OwnedTest_ProposedState is ProposedState {
    function testCannotClaimOwnership_Unauthorized() public {
        vm.startPrank(alien);

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "PROPOSED_OWNER"));
        ownedMock.claimOwnership();
    }

    function testClaimOwnership() public {
        vm.startPrank(owner);

        // event
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(this), owner);
        ownedMock.claimOwnership();
        // owner
        assertEq(ownedMock.owner(), owner);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract OwnedMock is Owned {
    function initialize() public initializer {
        __Owned_init();
    }
}
