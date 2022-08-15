// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {StateSender} from "contracts/root/StateSender.sol";

import "../utils/TestPlus.sol";

contract StateSenderTest is TestPlus {
    event StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    StateSender stateSender;

    address receiver;
    bytes maxData;
    bytes moreThanMaxData;

    function setUp() public {
        stateSender = new StateSender();
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
        bytes memory maxData = new bytes(stateSender.MAX_LENGTH());
        address receiver = makeAddr("receiver");

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
