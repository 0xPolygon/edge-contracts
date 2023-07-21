// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {StateSender} from "contracts/root/StateSender.sol";


abstract contract StateSenderHelper {
    StateSender stateSender;

    function setUp() public virtual {
        stateSender = new StateSender();
    }
}

contract StateSenderTest is StateSenderHelper, Test {
    event StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    address receiver;
    bytes maxData;
    bytes moreThanMaxData;

    function setUp() public virtual override {
        super.setUp();
        receiver = makeAddr("receiver");
        maxData = new bytes(stateSender.MAX_LENGTH());
        moreThanMaxData = new bytes(stateSender.MAX_LENGTH() + 1);
    }

    function testConstructor() public {
        assertEq(stateSender.counter(), 0);
    }

    function testCannotSyncState_InvalidReceiver() public {
        vm.expectRevert("INVALID_RECEIVER");
        stateSender.syncState(address(0), "");
    }

    function testCannotSyncState_ExceedsMaxLength() public {
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        stateSender.syncState(receiver, moreThanMaxData);
    }

    function testSyncState_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit StateSynced(1, address(this), receiver, maxData);
        stateSender.syncState(receiver, maxData);
    }

    function testSyncState_IncreasesCounter() public {
        stateSender.syncState(receiver, maxData);
        stateSender.syncState(receiver, maxData);
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        stateSender.syncState(receiver, moreThanMaxData);
        stateSender.syncState(receiver, maxData);
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        stateSender.syncState(receiver, moreThanMaxData);

        assertEq(stateSender.counter(), 3);
    }
}
