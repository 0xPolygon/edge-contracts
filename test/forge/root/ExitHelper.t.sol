// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {ExitHelper} from "contracts/root/ExitHelper.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/root/ICheckpointManager.sol";
import "contracts/interfaces/root/IExitHelper.sol";

abstract contract Uninitialized is Test {
    ExitHelper exitHelper;
    CheckpointManager checkpointManager;
    BLS bls;
    BN256G2 bn256G2;

    uint256 submitCounter;
    uint256 validatorSetSize;
    ICheckpointManager.Validator[] public validatorSet;
    IExitHelper.BatchExitInput[] public batchExitInput;

    address public admin;
    address public alice;
    address public bob;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    bytes32[] public hashes;
    bytes32[] public proof;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    bytes[] public unhashedLeaves;
    bytes32[][] public proves;
    bytes32[][] public leavesArray;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        checkpointManager = new CheckpointManager();
        exitHelper = new ExitHelper();

        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/root/generateMsgProof.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        bytes memory out = vm.ffi(cmd);

        ICheckpointManager.Validator[] memory validatorSetTmp;

        (
            validatorSetSize,
            validatorSetTmp,
            aggMessagePoints,
            hashes,
            bitmaps,
            unhashedLeaves,
            proves,
            leavesArray
        ) = abi.decode(
            out,
            (
                uint256,
                ICheckpointManager.Validator[],
                uint256[2][],
                bytes32[],
                bytes[],
                bytes[],
                bytes32[][],
                bytes32[][]
            )
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }
        submitCounter = 1;

        checkpointManager.initialize(bls, bn256G2, submitCounter, validatorSet);
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        exitHelper.initialize(checkpointManager);
    }
}

abstract contract CheckpointSubmitted is Initialized {
    function setUp() public virtual override {
        super.setUp();

        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 1,
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint.blockNumber,
                leavesArray[0][leafIndex],
                leafIndex,
                proves[0]
            ),
            true
        );
    }
}

abstract contract ExitHelperExitted is CheckpointSubmitted {
    function setUp() public virtual override {
        super.setUp();
        uint256 id = 0;
        uint256 blockNumber = 1;
        uint256 leafIndex = 0;
        assertEq(exitHelper.processedExits(id), false);
        exitHelper.exit(blockNumber, leafIndex, unhashedLeaves[0], proves[0]);
        assertEq(exitHelper.processedExits(id), true);
    }
}

contract ExitHelper_Initialize is Uninitialized {
    function testCannotInitialize_InvalidAddress() public {
        CheckpointManager checkpointManager_null;
        vm.expectRevert("ExitHelper: INVALID_ADDRESS");
        exitHelper.initialize(checkpointManager_null);
    }

    function testInitialize() public {
        exitHelper.initialize(checkpointManager);
        assertEq(
            keccak256(abi.encode(exitHelper.checkpointManager())),
            keccak256(abi.encode(address(checkpointManager)))
        );
    }
}

contract ExitHelper_ExitFailedBeforeInitialized is Uninitialized {
    function testCannotExit_Uninitialized() public {
        uint256 blockNumber = 0;
        uint256 leafIndex = 0;
        bytes memory unhashedLeaf = abi.encodePacked(block.timestamp);
        proof.push(keccak256(abi.encodePacked(block.timestamp)));

        vm.expectRevert("ExitHelper: NOT_INITIALIZED");
        exitHelper.exit(blockNumber, leafIndex, unhashedLeaf, proof);
    }

    function testCannotBatchExit_Uninitialized() public {
        uint256 blockNumber = 0;
        uint256 leafIndex = 0;
        bytes memory unhashedLeaf = abi.encodePacked(block.timestamp);
        proof.push(keccak256(abi.encodePacked(block.timestamp)));

        vm.expectRevert("ExitHelper: NOT_INITIALIZED");
        batchExitInput.push(IExitHelper.BatchExitInput(blockNumber, leafIndex, unhashedLeaf, proof));
        exitHelper.batchExit(batchExitInput);
    }
}

contract ExitHelper_Exit is Initialized {
    function testExit() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 1,
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint.blockNumber,
                leavesArray[0][leafIndex],
                leafIndex,
                proves[0]
            ),
            true
        );

        uint256 id = 0;
        assertEq(exitHelper.processedExits(id), false);

        exitHelper.exit(checkpoint.blockNumber, leafIndex, unhashedLeaves[0], proves[0]);
        assertEq(exitHelper.processedExits(id), true);
    }
}

contract ExitHelper_ExitFailedAfterInitialized is CheckpointSubmitted {
    function testCannotExit_InvalidProof() public {
        uint256 blockNumber = 1;
        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));

        vm.expectRevert("ExitHelper: INVALID_PROOF");
        exitHelper.exit(blockNumber, leafIndex, unhashedLeaves[0], proof);
    }
}

contract ExitHelper_ExitFailedAfterSubmitted is ExitHelperExitted {
    function testCannotExit_AlreadyProcessed() public {
        uint256 blockNumber = 0;
        uint256 leafIndex = 0;

        vm.expectRevert("ExitHelper: EXIT_ALREADY_PROCESSED");
        exitHelper.exit(blockNumber, leafIndex, unhashedLeaves[0], proves[0]);
    }
}

contract ExitHelper_BatchExit is ExitHelperExitted {
    function testBatchExit() public {
        ICheckpointManager.Checkpoint memory checkpoint1 = ICheckpointManager.Checkpoint({
            epoch: 2,
            blockNumber: 2,
            eventRoot: hashes[3]
        });

        ICheckpointManager.Checkpoint memory checkpoint2 = ICheckpointManager.Checkpoint({
            epoch: 3,
            blockNumber: 3,
            eventRoot: hashes[3]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint1, aggMessagePoints[1], validatorSet, bitmaps[1]);

        checkpointManager.submit(checkpointMetadata, checkpoint2, aggMessagePoints[2], validatorSet, bitmaps[1]);

        uint256 leafIndex1 = 0;
        uint256 leafIndex2 = 1;
        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint1.blockNumber,
                leavesArray[1][leafIndex1],
                leafIndex1,
                proves[1]
            ),
            true
        );

        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint2.blockNumber,
                leavesArray[1][leafIndex2],
                leafIndex2,
                proves[2]
            ),
            true
        );

        batchExitInput.push(
            IExitHelper.BatchExitInput(checkpoint1.blockNumber, leafIndex1, unhashedLeaves[1], proves[1])
        );

        uint256 id = 1;
        assertEq(exitHelper.processedExits(id), false);
        assertEq(exitHelper.processedExits(id + 1), false);

        exitHelper.batchExit(batchExitInput);

        assertEq(exitHelper.processedExits(id), true);
        assertEq(exitHelper.processedExits(id + 1), false);

        batchExitInput.push(
            IExitHelper.BatchExitInput(checkpoint2.blockNumber, leafIndex2, unhashedLeaves[2], proves[2])
        );

        exitHelper.batchExit(batchExitInput);

        assertEq(exitHelper.processedExits(id), true);
        assertEq(exitHelper.processedExits(id + 1), true);
    }
}
