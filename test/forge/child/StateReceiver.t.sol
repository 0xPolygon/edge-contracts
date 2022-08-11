// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {StateReceiver} from "contracts/child/StateReceiver.sol";
import {System} from "contracts/child/StateReceiver.sol";
import {StateReceivingContract} from "contracts/mocks/StateReceivingContract.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";

contract StateSenderTest is TestPlus, System {
    event StateSyncResult(uint256 indexed counter, StateReceiver.ResultStatus indexed status, bytes32 message);

    StateReceiver stateReceiver;
    StateReceivingContract stateReceivingContract;

    function setUp() public {
        stateReceiver = new StateReceiver();
        stateReceivingContract = new StateReceivingContract();

        vm.startPrank(SYSTEM);
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(true));
    }

    function testConstructor() public {
        assertEq(stateReceiver.counter(), 0);
    }

    function testCannotStateSync_Unauthorized() public {
        changePrank(address(this));
        StateReceiver.StateSync memory obj;

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        stateReceiver.stateSync(obj, "");
    }

    function testCannotStateSync_SignatureVerificationFailed() public {
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(false));
        StateReceiver.StateSync memory obj;

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        stateReceiver.stateSync(obj, "");
    }

    function testCannotStateSync_IdNotSequential() public {
        StateReceiver.StateSync memory obj;
        obj.id = 2; // id=2, counter=0

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        stateReceiver.stateSync(obj, "");
    }

    function testStateSync_Skip() public {
        // this will be skipped because the receiver has no code
        StateReceiver.StateSync memory objNoCode;
        objNoCode.id = 1;

        // this will be skipped because it is flagged
        StateReceiver.StateSync memory objFlagged;
        objFlagged.id = 2;
        objFlagged.receiver = address(stateReceivingContract);
        objFlagged.skip = true;

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(objNoCode.id, StateReceiver.ResultStatus.SKIP, "");
        stateReceiver.stateSync(objNoCode, "");
        // counter
        assertEq(stateReceiver.counter(), 1);

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(objFlagged.id, StateReceiver.ResultStatus.SKIP, "");
        stateReceiver.stateSync(objFlagged, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
    }

    function testStateSync_Success() public {
        StateReceiver.StateSync memory obj;
        obj.id = 1;
        obj.receiver = address(stateReceivingContract);
        obj.data = abi.encode(uint256(1337));

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(obj.id, StateReceiver.ResultStatus.SUCCESS, bytes32(obj.data));
        stateReceiver.stateSync(obj, "");
        // counter
        assertEq(stateReceiver.counter(), 1);
        // data
        assertEq(stateReceivingContract.counter(), 1337);
    }

    function testStateSync_Failure() public {
        // stateReceivingContract will revert on empty data
        StateReceiver.StateSync memory obj;
        obj.id = 1;
        obj.receiver = address(stateReceivingContract);

        // event
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(obj.id, StateReceiver.ResultStatus.FAILURE, "");
        stateReceiver.stateSync(obj, "");
        // counter
        assertEq(stateReceiver.counter(), 1);
    }

    function testCannotStateSyncBatch_Unauthorized() public {
        changePrank(address(this));
        StateReceiver.StateSync[] memory objs;

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        stateReceiver.stateSyncBatch(objs, "");
    }

    function testCannotStateSyncBatch_NoStateSyncData() public {
        StateReceiver.StateSync[] memory objs;

        vm.expectRevert("NO_STATESYNC_DATA");
        stateReceiver.stateSyncBatch(objs, "");
    }

    function testCannotStateSyncBatch_SignatureVerificationFailed() public {
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(false));
        StateReceiver.StateSync[] memory objs = new StateReceiver.StateSync[](2);

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        stateReceiver.stateSyncBatch(objs, "");
    }

    function testCannotStateSyncBatch_IdNotSequential() public {
        StateReceiver.StateSync[] memory objs = new StateReceiver.StateSync[](2);
        objs[0].id = 1; // id=1, counter=0
        objs[1].id = 3; // id=3, counter=1

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        stateReceiver.stateSyncBatch(objs, "");
    }

    function testStateSyncBatch_Skip() public {
        StateReceiver.StateSync[] memory objs = new StateReceiver.StateSync[](2);
        // this will be skipped because the receiver has no code
        objs[0].id = 1;
        // this will be skipped because it is flagged
        objs[1].id = 2;
        objs[1].receiver = address(stateReceivingContract);
        objs[1].skip = true;

        // events
        for (uint256 i; i < objs.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit StateSyncResult(objs[i].id, StateReceiver.ResultStatus.SKIP, "");
        }
        stateReceiver.stateSyncBatch(objs, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
    }

    function testStateSyncBatch_Success() public {
        StateReceiver.StateSync[] memory objs = new StateReceiver.StateSync[](2);
        objs[0].id = 1;
        objs[0].receiver = address(stateReceivingContract);
        objs[0].data = abi.encode(uint256(1337));
        objs[1].id = 2;
        objs[1].receiver = address(stateReceivingContract);
        objs[1].data = abi.encode(uint256(1338));
        uint256 dataSum;

        // events
        for (uint256 i; i < objs.length; ++i) {
            dataSum += abi.decode(objs[i].data, (uint256));

            vm.expectEmit(true, true, false, true);
            emit StateSyncResult(objs[i].id, StateReceiver.ResultStatus.SUCCESS, bytes32(dataSum));
        }
        stateReceiver.stateSyncBatch(objs, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
        // data
        assertEq(stateReceivingContract.counter(), dataSum);
    }

    function testStateSyncBatch_Failure() public {
        // stateReceivingContract will revert on empty data
        StateReceiver.StateSync[] memory objs = new StateReceiver.StateSync[](2);
        objs[0].id = 1;
        objs[0].receiver = address(stateReceivingContract);
        objs[1].id = 2;
        objs[1].receiver = address(stateReceivingContract);

        // events
        for (uint256 i; i < objs.length; ++i) {
            vm.expectEmit(true, true, false, true);
            emit StateSyncResult(objs[i].id, StateReceiver.ResultStatus.FAILURE, "");
        }
        stateReceiver.stateSyncBatch(objs, "");
        // counter
        assertEq(stateReceiver.counter(), 2);
    }
}
