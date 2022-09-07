// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {StateReceiver} from "contracts/child/StateReceiver.sol";
import {System} from "contracts/child/StateReceiver.sol";
import {StateReceivingContract} from "contracts/mocks/StateReceivingContract.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";
import {MurkyBase} from "murky/common/MurkyBase.sol";

abstract contract EmptyState is TestPlus, System, StateReceiver {
    StateReceiver stateReceiver;
    StateReceivingContract stateReceivingContract;

    StateSyncBundle bundle;
    address receiver;

    function setUp() public virtual {
        stateReceiver = new StateReceiver();
        stateReceivingContract = new StateReceivingContract();
        receiver = address(stateReceivingContract);

        vm.startPrank(SYSTEM);
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(true));
    }

    /// @dev Use with assertEq
    function _getBundle(uint256 index) internal view returns (StateReceiver.StateSyncBundle memory) {
        (uint256 _startId, uint256 _endId, uint256 _leaves, bytes32 _root) = stateReceiver.bundles(index);
        return StateReceiver.StateSyncBundle(_startId, _endId, _leaves, _root);
    }

    /// @notice Helper for passing obj in calldata
    function executeStateSyncHelper(uint256 prevId, StateSync calldata obj) external {
        _executeStateSync(prevId, obj);
    }
}

contract StateReceiverTest_EmptyState is EmptyState {
    function testConstructor() public {
        assertEq(stateReceiver.counter(), 0, "Counter");
        assertEq(stateReceiver.bundleCounter(), 1, "Bundle counter");
        assertEq(stateReceiver.lastExecutedBundleCounter(), 1, "Last executed bundle counter");
        assertEq(stateReceiver.lastCommittedId(), 0, "Last committed ID");
        assertEq(stateReceiver.currentLeafIndex(), 0, "Current leaf index");
    }

    function testCannotCommit_Unauthorized() public {
        changePrank(address(this));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        stateReceiver.commit(bundle, "");
    }

    function testCannotCommit_InvalidStartId() public {
        bundle.startId = 0;

        vm.expectRevert("INVALID_START_ID");
        stateReceiver.commit(bundle, "");

        bundle.startId = 2;

        vm.expectRevert("INVALID_START_ID");
        stateReceiver.commit(bundle, "");
    }

    function testCannotCommit_InvalidEndId() public {
        bundle.startId = 1;
        bundle.endId = 0;

        vm.expectRevert("INVALID_END_ID");
        stateReceiver.commit(bundle, "");
    }

    function testCannotCommit_SignatureVerificationFailed() public {
        bundle.startId = 1;
        bundle.endId = 1337;
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(false));

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        stateReceiver.commit(bundle, "");
    }

    function testCommit() public {
        bundle.startId = 1;
        bundle.endId = 1337;

        stateReceiver.commit(bundle, "");

        assertEq(stateReceiver.bundleCounter(), 2, "Bundle counter");
        assertEq(_getBundle(1), bundle);
        assertEq(stateReceiver.lastCommittedId(), 1337, "Last committed ID");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    StateSync state;

    function testCannotExecuteStateSync_IdNotSequential() public {
        state.id = 0;

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        this.executeStateSyncHelper(0, state);
    }

    function testExecuteStateSync_Skip() public {
        state.id = 1;
        state.receiver = address(0);

        // this will be skipped because receiver has no code
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, ResultStatus.SKIP, "");
        this.executeStateSyncHelper(0, state);

        // this will be skipped because it's flagged
        state.receiver = receiver;
        state.skip = true;

        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, ResultStatus.SKIP, "");
        this.executeStateSyncHelper(0, state);
    }

    function testExecuteStateSync_Success() public {
        state.id = 1;
        state.receiver = receiver;
        state.data = abi.encode(uint256(1337));

        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, ResultStatus.SUCCESS, bytes32(uint256(1337)));
        this.executeStateSyncHelper(0, state);
        assertEq(stateReceivingContract.counter(), 1337);
    }

    function testExecuteStateSync_Failure() public {
        state.id = 1;
        state.receiver = receiver;
        state.data = "";
        bytes memory callData = abi.encodeCall(
            stateReceivingContract.onStateReceive,
            (state.id, state.sender, state.data)
        );

        vm.expectCall(receiver, callData);
        // StateReceivingContract will revert on empty data
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(state.id, ResultStatus.FAILURE, "");
        this.executeStateSyncHelper(0, state);
    }
}

abstract contract NonEmptyState is EmptyState, MurkyBase {
    /// @dev Copying of StateSync[] from memory to storage is not supported yet,
    /// @dev so we store them ABI-encoded
    /// @dev Use _getBatch(index) for better DX
    bytes[] batchesData;
    bytes32[][] proofFor;
    bytes32[] leaves;

    function setUp() public virtual override {
        super.setUp();
        // create bundle of size bundleSize with batches of size batchSize;
        // syncs will be successful, with data uint256(1337)
        uint256 batchSize = 2;
        uint256 bundleSize = 2;
        StateSync[][] memory _batches = new StateSync[][](bundleSize);
        StateSync[] memory _states = new StateSync[](batchSize);
        uint256 stateId;
        for (uint256 i; i < bundleSize; ++i) {
            for (uint256 j; j < batchSize; ++j) {
                StateSync memory _state;
                _state.receiver = receiver;
                _state.data = abi.encode(uint256(1337));
                _state.id = ++stateId;
                _states[j] = _state;
            }
            _batches[i] = _states;
            batchesData.push(abi.encode(_batches[i]));
            leaves.push(keccak256(abi.encode(_batches[i])));
        }
        for (uint256 i; i < bundleSize; ++i) {
            proofFor.push(getProof(leaves, i));
        }

        // commit bundle
        StateSyncBundle memory _bundle;
        _bundle.startId = 1;
        _bundle.endId = bundleSize * batchSize;
        _bundle.leaves = bundleSize;
        _bundle.root = getRoot(leaves);
        stateReceiver.commit(_bundle, "");
    }

    /// @notice Hashing function for Murky
    function hashLeafPairs(bytes32 left, bytes32 right) public pure override returns (bytes32 _hash) {
        _hash = keccak256(abi.encode(left, right));
    }

    /// @notice Helper for reading batchesData
    function _getBatch(uint256 index) internal view returns (StateSync[] memory) {
        return abi.decode(batchesData[index], (StateSync[]));
    }
}

contract StateReceiverTest_NonEmptyState is NonEmptyState {
    function testCannotExecute_InvalidProof() public {
        vm.expectRevert("INVALID_PROOF");
        stateReceiver.execute(proofFor[1], _getBatch(0));
    }

    function testExecute_OneBatch() public {
        stateReceiver.execute(proofFor[0], _getBatch(0));

        assertEq(stateReceiver.counter(), 2, "Counter");
        assertEq(stateReceiver.lastExecutedBundleCounter(), 1, "Last executed bundle counter");
        assertEq(stateReceiver.currentLeafIndex(), 1, "Current leaf index");
        assertEq(stateReceivingContract.counter(), 1337 * 2, "State receiving contract");
    }

    function testExecute_WholeBundle() public {
        stateReceiver.execute(proofFor[0], _getBatch(0));

        stateReceiver.execute(proofFor[1], _getBatch(1));

        assertEq(stateReceiver.counter(), 4, "Counter");
        assertEq(stateReceiver.lastExecutedBundleCounter(), 2, "Last executed bundle counter");
        assertEq(stateReceiver.currentLeafIndex(), 0, "Current leaf index");
        assertEq(_getBundle(0), bundle); // empty (deleted)
        assertEq(stateReceivingContract.counter(), 1337 * 4, "State receiving contract");
    }

    function testCannotExecute_NothingToExecute() public {
        stateReceiver.execute(proofFor[0], _getBatch(0));
        stateReceiver.execute(proofFor[1], _getBatch(1));
        StateReceiver.StateSync[] memory states;
        bytes32[] memory proof;

        vm.expectRevert("NOTHING_TO_EXECUTE");
        stateReceiver.execute(proof, states);
    }
}
