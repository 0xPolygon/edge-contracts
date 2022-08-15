// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {StateReceiver} from "contracts/child/StateReceiver.sol";
import {System} from "contracts/child/StateReceiver.sol";
import {StateReceivingContract} from "contracts/mocks/StateReceivingContract.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";

// TODO StateReceiver was updated
contract StateReceiverTest is TestPlus, System {
    /*event StateSyncResult(uint256 indexed counter, StateReceiver.ResultStatus indexed status, bytes32 message);

    StateReceiver stateReceiver;
    StateReceivingContract stateReceivingContract;

    StateReceiver.StateSync state;

    address receiver;

    function setUp() public {
        stateReceiver = new StateReceiver();
        stateReceivingContract = new StateReceivingContract();

        receiver = address(stateReceivingContract);

        vm.startPrank(SYSTEM);
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(true));
    }

    function testConstructor() public {
        assertEq(stateReceiver.counter(), 0);
    }

    function testCannotStateSync_Unauthorized() public {
        changePrank(address(this));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        stateReceiver.stateSync(state, "");
    }

    function testCannotStateSync_SignatureVerificationFailed() public {
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(false));

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        stateReceiver.stateSync(state, "");
    }

    function testCannotStateSync_IdNotSequential() public {
        state.id = 2; // id=2, counter=0

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        stateReceiver.stateSync(state, "");
    }

    function testStateSync_Skip() public {
        // this will be skipped because the receiver has no code
        state.id = 1;

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, StateReceiver.ResultStatus.SKIP, "");
        stateReceiver.stateSync(state, "");
        // counter
        assertEq(stateReceiver.counter(), 1);

        // this will be skipped because it is flagged
        state.id = 2;
        state.receiver = receiver;
        state.skip = true;

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, StateReceiver.ResultStatus.SKIP, "");
        stateReceiver.stateSync(state, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
    }

    function testStateSync_Success() public {
        state.id = 1;
        state.receiver = receiver;
        state.data = abi.encode(uint256(1337));

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, StateReceiver.ResultStatus.SUCCESS, bytes32(state.data));
        stateReceiver.stateSync(state, "");
        // counter
        assertEq(stateReceiver.counter(), 1);
        // data
        assertEq(stateReceivingContract.counter(), 1337);
    }

    function testStateSync_Failure() public {
        // stateReceivingContract will revert on empty data
        state.id = 1;
        state.receiver = receiver;

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, StateReceiver.ResultStatus.FAILURE, "");
        stateReceiver.stateSync(state, "");
        // counter
        assertEq(stateReceiver.counter(), 1);
    }

    function testCannotStateSyncBatch_Unauthorized() public {
        changePrank(address(this));
        StateReceiver.StateSync[] memory states;

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        stateReceiver.stateSyncBatch(states, "");
    }

    function testCannotStateSyncBatch_NoStateSyncData() public {
        StateReceiver.StateSync[] memory states;

        vm.expectRevert("NO_STATESYNC_DATA");
        stateReceiver.stateSyncBatch(states, "");
    }

    function testCannotStateSyncBatch_SignatureVerificationFailed() public {
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(false));
        StateReceiver.StateSync[] memory states = new StateReceiver.StateSync[](2);

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        stateReceiver.stateSyncBatch(states, "");
    }

    function testCannotStateSyncBatch_IdNotSequential() public {
        StateReceiver.StateSync[] memory states = new StateReceiver.StateSync[](2);
        states[0].id = 1; // id=1, counter=0
        states[1].id = 3; // id=3, counter=1

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        stateReceiver.stateSyncBatch(states, "");
    }

    function testStateSyncBatch_Skip() public {
        StateReceiver.StateSync[] memory states = new StateReceiver.StateSync[](2);
        // this will be skipped because the receiver has no code
        states[0].id = 1;
        // this will be skipped because it is flagged
        states[1].id = 2;
        states[1].receiver = receiver;
        states[1].skip = true;

        // events
        for (uint256 i; i < states.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit StateSyncResult(states[i].id, StateReceiver.ResultStatus.SKIP, "");
        }
        stateReceiver.stateSyncBatch(states, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
    }

    function testStateSyncBatch_Success() public {
        StateReceiver.StateSync[] memory states = new StateReceiver.StateSync[](2);
        states[0].id = 1;
        states[0].receiver = receiver;
        states[0].data = abi.encode(uint256(1337));
        states[1].id = 2;
        states[1].receiver = receiver;
        states[1].data = abi.encode(uint256(1338));
        uint256 dataSum;

        // events
        for (uint256 i; i < states.length; ++i) {
            dataSum += abi.decode(states[i].data, (uint256));

            vm.expectEmit(true, true, false, true);
            emit StateSyncResult(states[i].id, StateReceiver.ResultStatus.SUCCESS, bytes32(dataSum));
        }
        stateReceiver.stateSyncBatch(states, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
        // data
        assertEq(stateReceivingContract.counter(), dataSum);
    }

    function testStateSyncBatch_Failure() public {
        // stateReceivingContract will revert on empty data
        StateReceiver.StateSync[] memory states = new StateReceiver.StateSync[](2);
        states[0].id = 1;
        states[0].receiver = receiver;
        states[1].id = 2;
        states[1].receiver = receiver;

        // events
        for (uint256 i; i < states.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit StateSyncResult(states[i].id, StateReceiver.ResultStatus.FAILURE, "");
        }
        stateReceiver.stateSyncBatch(states, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
    }*/
}
