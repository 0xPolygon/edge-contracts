// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
    bytes32[] public proof;
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
        (uint256 _startId, uint256 _endId, bytes32 _root) = stateReceiver.bundles(index);
        return StateReceiver.StateSyncBundle(_startId, _endId, _root);
    }

    /// @notice Helper for passing obj in calldata
    function executeStateSyncHelper(uint256 prevId, StateSync calldata obj) external {}
}

contract StateReceiverTest_EmptyState is EmptyState {
    function testConstructor() public {
        assertEq(stateReceiver.bundleCounter(), 0, "Bundle counter");
        assertEq(stateReceiver.lastCommittedId(), 0, "Last committed ID");
    }

    function testCannotCommit_Unauthorized() public {
        changePrank(address(this));

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        stateReceiver.commit(bundle, "", "");
    }

    function testCannotCommit_InvalidStartId() public {
        bundle.startId = 0;

        vm.expectRevert("INVALID_START_ID");
        stateReceiver.commit(bundle, "", "");

        bundle.startId = 2;

        vm.expectRevert("INVALID_START_ID");
        stateReceiver.commit(bundle, "", "");
    }

    function testCannotCommit_InvalidEndId() public {
        bundle.startId = 1;
        bundle.endId = 0;

        vm.expectRevert("INVALID_END_ID");
        stateReceiver.commit(bundle, "", "");
    }

    function testCannotCommit_SignatureVerificationFailed() public {
        bundle.startId = 1;
        bundle.endId = 1337;
        vm.mockCall(VALIDATOR_PKCHECK_PRECOMPILE, "", abi.encode(false));

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        stateReceiver.commit(bundle, "", "");
    }

    function testCommit() public {
        bundle.startId = 1;
        bundle.endId = 1337;

        stateReceiver.commit(bundle, "", "");

        assertEq(stateReceiver.bundleCounter(), 1, "Bundle counter");
        assertEq(_getBundle(0), bundle);
        assertEq(stateReceiver.lastCommittedId(), 1337, "Last committed ID");
    }
}

abstract contract NonEmptyState is EmptyState, MurkyBase {
    /// @dev Copying of StateSync[] from memory to storage is not supported yet,
    /// @dev so we store them ABI-encoded
    /// @dev Use _getBatch(index) for better DX
    bytes32[] leaves;
    StateSync[] stateSyncs;
    bytes32[][] proofs;

    function setUp() public virtual override {
        super.setUp();
        // create bundle of size bundleSize with batches of size batchSize;
        // syncs will be successful, with data uint256(1337)
        uint256 bundleSize = 5;
        uint256 counter = stateReceiver.lastCommittedId();
        StateSync memory _state;
        for (uint256 i; i < bundleSize - 3; ++i) {
            _state.receiver = receiver;
            _state.data = abi.encode(uint256(1337));
            _state.sender = address(0);
            _state.id = ++counter;
            stateSyncs.push(_state);
            leaves.push(keccak256(abi.encode(_state)));
        }

        // this will be skipped because receiver has no code
        _state.receiver = address(0);
        _state.id = ++counter;
        stateSyncs.push(_state);
        leaves.push(keccak256(abi.encode(_state)));

        // this will be skipped because it's flagged
        _state.receiver = receiver;
        _state.id = ++counter;
        _state.skip = true;
        stateSyncs.push(_state);
        leaves.push(keccak256(abi.encode(_state)));

        // StateReceivingContract will revert on empty data
        _state.receiver = receiver;
        _state.id = ++counter;
        _state.skip = false;
        _state.data = "";
        stateSyncs.push(_state);
        leaves.push(keccak256(abi.encode(_state)));

        for (uint256 i; i < bundleSize; ++i) {
            proofs.push(getProof(leaves, i));
        }

        // commit bundle
        StateSyncBundle memory _bundle;
        _bundle.startId = 1;
        _bundle.endId = bundleSize;
        _bundle.root = getRoot(leaves);
        stateReceiver.commit(_bundle, "", "");
    }

    /// @notice Hashing function for Murky
    function hashLeafPairs(bytes32 left, bytes32 right) public pure override returns (bytes32 _hash) {
        _hash = keccak256(abi.encode(left, right));
    }
}

contract StateReceiverTest_NonEmptyState is NonEmptyState {
    function testCannotExecute_InvalidProof() public {
        vm.expectRevert("INVALID_PROOF");
        stateReceiver.execute(proof, stateSyncs[0]);
    }

    function testCannotExecuteStateSync_IdNotSequential() public {
        StateSync memory state;
        state.id = 6;

        vm.expectRevert("StateReceiver: NO_BUNDLE_FOR_STATESYNC_ID");
        stateReceiver.execute(proof, state);
    }

    function testExecuteStateSync_Skip() public {
        // this will be skipped because receiver has no code
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(stateSyncs[2].id, ResultStatus.SKIP, "");
        stateReceiver.execute(proofs[2], stateSyncs[2]);

        // this will be skipped because it's flagged
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(stateSyncs[3].id, ResultStatus.SKIP, "");
        stateReceiver.execute(proofs[3], stateSyncs[3]);
    }

    function testExecuteStateSync_Success() public {
        emit StateSyncResult(stateSyncs[0].id, ResultStatus.SUCCESS, abi.encode(uint256(1337)));
        stateReceiver.execute(proofs[0], stateSyncs[0]);
        assertEq(stateReceivingContract.counter(), 1337);
    }

    function testExecuteStateSync_Failure() public {
        vm.expectCall(receiver, stateSyncs[4].data);
        // StateReceivingContract will revert on empty data
        vm.expectEmit(true, true, false, true);
        emit StateSyncResult(stateSyncs[4].id, ResultStatus.FAILURE, "");
        stateReceiver.execute(proofs[4], stateSyncs[4]);
    }

    function testBatchExecute_Success() public {
        stateReceiver.batchExecute(proofs, stateSyncs);

        //Only 2 cases were executed
        assertEq(stateReceivingContract.counter(), 1337 * 2);
    }
}
