// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/root/ICheckpointManager.sol";

abstract contract Uninitialized is Test {
    CheckpointManager checkpointManager;
    BLS bls;
    BN256G2 bn256G2;

    uint256 submitCounter;
    uint256 validatorSetSize;
    ICheckpointManager.Validator[] public validatorSet;

    address public admin;
    address public alice;
    address public bob;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    bytes32[] public hashes;
    bytes32[] public proof;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    uint256[] public aggVotingPowers;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        checkpointManager = new CheckpointManager();

        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/root/generateMsg.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        bytes memory out = vm.ffi(cmd);

        ICheckpointManager.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, bitmaps, aggVotingPowers) = abi.decode(
            out,
            (uint256, ICheckpointManager.Validator[], uint256[2][], bytes32[], bytes[], uint256[])
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }
        submitCounter = 1;
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        checkpointManager.initialize(bls, bn256G2, submitCounter, validatorSet);
    }
}

abstract contract FirstSubmitted is Initialized {
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

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[3], validatorSet, bitmaps[3]);
    }
}

contract CheckpointManager_Initialize is Uninitialized {
    function testInitialize() public {
        checkpointManager.initialize(bls, bn256G2, submitCounter, validatorSet);

        assertEq(keccak256(abi.encode(checkpointManager.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(checkpointManager.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        assertEq(checkpointManager.currentValidatorSetLength(), validatorSetSize);
        for (uint256 i = 0; i < validatorSetSize; i++) {
            (address _address, uint256 votingPower) = checkpointManager.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}

contract CheckpointManager_Submit is Initialized {
    function testCannotSubmit_InvalidValidatorSetHash() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 0, //For Invalid Signature
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[1] //Invalid Hash
        });

        vm.expectRevert("INVALID_VALIDATOR_SET_HASH");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);
    }

    function testCannotSubmit_InvalidSignature() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 0, //For Invalid Signature
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);
    }

    function testCannotSubmit_EmptyBitmap() public {
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

        vm.expectRevert("BITMAP_IS_EMPTY");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[1], validatorSet, bitmaps[1]);
    }

    function testCannotSubmit_NotEnoughPower() public {
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

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[2], validatorSet, bitmaps[2]);
    }

    function testSubmit_First() public {
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

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[3], validatorSet, bitmaps[3]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        checkpointManager.getEventMembershipByBlockNumber(
            checkpoint.blockNumber,
            checkpoint.eventRoot,
            leafIndex,
            proof
        );
        checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
    }
}

contract CheckpointManager_SubmitSecond is FirstSubmitted {
    function testCannotSubmit_InvalidEpoch() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 0,
            blockNumber: 0,
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        vm.expectRevert("INVALID_EPOCH");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[4], validatorSet, bitmaps[4]);
    }

    function testCannotSubmit_EmptyCheckpoint() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 0,
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        vm.expectRevert("EMPTY_CHECKPOINT");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[5], validatorSet, bitmaps[5]);
    }

    function testSubmit_SameEpoch() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 2,
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[6], validatorSet, bitmaps[6]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        checkpointManager.getEventMembershipByBlockNumber(
            checkpoint.blockNumber,
            checkpoint.eventRoot,
            leafIndex,
            proof
        );
        checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
    }

    function testSubmit_ShortBitmap() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 2,
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        if (aggVotingPowers[7] > (checkpointManager.totalVotingPower() * 2) / 3) {
            checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[7], validatorSet, bitmaps[7]);

            assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
            assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

            uint256 leafIndex = 0;
            proof.push(keccak256(abi.encodePacked(block.timestamp)));
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint.blockNumber,
                checkpoint.eventRoot,
                leafIndex,
                proof
            );
            checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
        } else {
            vm.expectRevert("INSUFFICIENT_VOTING_POWER");
            checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[7], validatorSet, bitmaps[7]);
        }
    }

    function testCannot_InvalidEventRootByBlockNumber() public {
        uint256 blockNumber = 3;
        bytes32 leaf = keccak256(abi.encodePacked(block.timestamp));
        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        vm.expectRevert("NO_EVENT_ROOT_FOR_BLOCK_NUMBER");
        checkpointManager.getEventMembershipByBlockNumber(blockNumber, leaf, leafIndex, proof);
    }

    function testCannot_InvalidEventRootByEpoch() public {
        uint256 epoch = 2;
        bytes32 leaf = keccak256(abi.encodePacked(block.timestamp));
        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        vm.expectRevert("NO_EVENT_ROOT_FOR_EPOCH");
        checkpointManager.getEventMembershipByEpoch(epoch, leaf, leafIndex, proof);
    }

    function testGetCheckpointBlock_BlockNumberIsCheckpointBlock() public {
        uint256 expectedCheckpointBlock = 1;
        uint256 blockNumber = 1;

        (bool isFound, uint256 foundCheckpointBlock) = checkpointManager.getCheckpointBlock(blockNumber);
        assertEq(foundCheckpointBlock, expectedCheckpointBlock);
        assertEq(isFound, true);
    }

    function testGetCheckpointBlock_NonExistingCheckpointBlock() public {
        uint256 expectedCheckpointBlock = 0;
        uint256 blockNumber = 5;

        (bool isFound, uint256 foundCheckpointBlock) = checkpointManager.getCheckpointBlock(blockNumber);
        assertEq(foundCheckpointBlock, expectedCheckpointBlock);
        assertEq(isFound, false);
    }
}
