// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {RootValidatorSet} from "contracts/root/RootValidatorSet.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import "contracts/interfaces/Errors.sol";

import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus {
    BLS bls;
    BN256G2 bn256G2;
    RootValidatorSet rootValidatorSet;
    CheckpointManager checkpointManager;
    uint256 public submitCounter;
    uint256 public startBlock;
    uint256 public validatorSetSize;
    address governance;
    address alice;
    address bob;
    bytes32 public domain;
    bytes32 public eventRoot;
    uint256[4][] public pubkeys;
    uint256[2][] public aggMessagePoints;
    uint256[] public validatorIds;
    RootValidatorSet.Validator public newValidator;
    RootValidatorSet.Validator[] public validators;
    CheckpointManager.Checkpoint[] public checkpoints;
    uint256[] public ids;

    // using Checkpoint for CheckpointManager.Checkpoint;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        rootValidatorSet = new RootValidatorSet();
        checkpointManager = new CheckpointManager();

        governance = makeAddr("governance");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
        newValidator._address = governance;

        domain = keccak256(abi.encodePacked(block.timestamp));
        eventRoot = keccak256(abi.encodePacked(block.timestamp, block.number));
        //initialize RootValidatorSet
        address[] memory addresses = new address[](validatorSetSize);
        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/root/generateMsg.ts";
        cmd[3] = vm.toString(abi.encode(domain, eventRoot, governance));
        bytes memory out = vm.ffi(cmd);

        (validatorSetSize, addresses, pubkeys, validatorIds, aggMessagePoints, newValidator.blsKey) = abi.decode(
            out,
            (uint256, address[], uint256[4][], uint256[], uint256[2][], uint256[4])
        );

        rootValidatorSet.initialize(governance, address(checkpointManager), addresses, pubkeys);

        assertEq(rootValidatorSet.currentValidatorId(), validatorSetSize);
        assertEq(rootValidatorSet.checkpointManager(), address(checkpointManager));

        uint256 i = 0;
        for (i = 0; i < validatorSetSize; i++) {
            RootValidatorSet.Validator memory validator = rootValidatorSet.getValidator(i + 1);

            assertEq(keccak256(abi.encode(validator.blsKey)), keccak256(abi.encode(pubkeys[i])));
            assertEq(validator._address, addresses[i]);
            assertEq(rootValidatorSet.validatorIdByAddress(addresses[i]), i + 1);
        }
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();

        checkpointManager.initialize(bls, bn256G2, rootValidatorSet, domain);
        (, uint256 endBlock, ) = checkpointManager.checkpoints(0);
        startBlock = endBlock + 1;
        submitCounter = checkpointManager.currentCheckpointId() + 1;
    }
}

contract CheckpointManager_Initialize is Uninitialized {
    function testInitialize() public {
        checkpointManager.initialize(bls, bn256G2, rootValidatorSet, domain);
        assertEq(keccak256(abi.encode(checkpointManager.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(checkpointManager.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        assertEq(
            keccak256(abi.encode(checkpointManager.rootValidatorSet())),
            keccak256(abi.encode(address(rootValidatorSet)))
        );
        assertEq(rootValidatorSet.activeValidatorSetSize(), validatorSetSize);
        assertEq(checkpointManager.domain(), domain);
    }
}

contract CheckpointManager_Submit is Initialized {
    function testCannotSubmit_InvalidLength() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        vm.expectRevert("NOT_ENOUGH_SIGNATURES");
        checkpointManager.submit(
            id,
            checkpoint,
            aggMessagePoints[0],
            new uint256[](0),
            new RootValidatorSet.Validator[](0)
        );
    }

    function testCannotSubmit_InvalidSignature() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 102, //For Invalid Signature
            eventRoot: eventRoot
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        checkpointManager.submit(
            id,
            checkpoint,
            aggMessagePoints[0],
            validatorIds,
            new RootValidatorSet.Validator[](0)
        );
    }

    function testCannotSubmit_NonSequentialId() public {
        uint256 id = submitCounter + 1; //For Not Sequential id
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        validators.push(newValidator);
        checkpointManager.submit(id, checkpoint, aggMessagePoints[1], validatorIds, validators);
    }

    function testCannotSubmit_InvalidStartBlock() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 2, //Invalid Start Block
            endBlock: 102,
            eventRoot: eventRoot
        });

        vm.expectRevert("INVALID_START_BLOCK");
        validators.push(newValidator);
        checkpointManager.submit(id, checkpoint, aggMessagePoints[2], validatorIds, validators);
    }

    function testCannotSubmit_EmptyCheckpoint() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 0, //endBlock < startBlock for EnptyCheckpoint
            eventRoot: eventRoot
        });

        vm.expectRevert("EMPTY_CHECKPOINT");
        validators.push(newValidator);
        checkpointManager.submit(id, checkpoint, aggMessagePoints[3], validatorIds, validators);
    }

    function testSubmit_WithoutValidators() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101, //endBlock < startBlock for EnptyCheckpoint
            eventRoot: eventRoot
        });

        uint256 currentValidatorIdBeforeSubmit = rootValidatorSet.currentValidatorId();
        checkpointManager.submit(
            id,
            checkpoint,
            aggMessagePoints[4],
            validatorIds,
            new RootValidatorSet.Validator[](0)
        );

        submitCounter = checkpointManager.currentCheckpointId() + 1;
        assertEq(submitCounter, 2);

        (, uint256 endBlock, ) = checkpointManager.checkpoints(submitCounter - 1);
        assertEq(endBlock, 101);
        startBlock = endBlock + 1;

        uint256 currentValidatorIdAfterSubmit = rootValidatorSet.currentValidatorId();
        assertEq(currentValidatorIdAfterSubmit, currentValidatorIdBeforeSubmit);
    }

    function testSubmit_WithAValidator() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101, //endBlock < startBlock for EnptyCheckpoint
            eventRoot: eventRoot
        });

        validators.push(newValidator);
        uint256 currentValidatorIdBeforeSubmit = rootValidatorSet.currentValidatorId();
        checkpointManager.submit(id, checkpoint, aggMessagePoints[5], validatorIds, validators);

        submitCounter = checkpointManager.currentCheckpointId() + 1;
        assertEq(submitCounter, 2);

        (, uint256 endBlock, ) = checkpointManager.checkpoints(submitCounter - 1);
        assertEq(endBlock, 101);
        startBlock = endBlock + 1;

        uint256 currentValidatorIdAfterSubmit = rootValidatorSet.currentValidatorId();
        assertEq(currentValidatorIdAfterSubmit - 1, currentValidatorIdBeforeSubmit);

        RootValidatorSet.Validator memory validator = rootValidatorSet.getValidator(currentValidatorIdAfterSubmit);
        assertEq(keccak256(abi.encode(newValidator._address)), keccak256(abi.encode(validator._address)));
        assertEq(keccak256(abi.encode(newValidator.blsKey)), keccak256(abi.encode(validator.blsKey)));
    }

    function testCannotSubmitBatch_LengthMismatch() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        CheckpointManager.Checkpoint memory checkpoint2 = CheckpointManager.Checkpoint({
            startBlock: 102,
            endBlock: 202,
            eventRoot: eventRoot
        });

        vm.expectRevert("LENGTH_MISMATCH");
        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        checkpoints.push(checkpoint2);
        ids.push(id);
        checkpointManager.submitBatch(ids, checkpoints, aggMessagePoints[6], validatorIds, validators);
    }

    function testCannotSubmitBatch_NonSequentialId() public {
        uint256 id = submitCounter + 1;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        vm.expectRevert("ID_NOT_SEQUENTIAL");
        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        ids.push(id);
        checkpointManager.submitBatch(ids, checkpoints, aggMessagePoints[7], validatorIds, validators);
    }

    function testCannotSubmitBatch_InvalidStartBlock() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 2, //Invalid Start Block
            endBlock: 102,
            eventRoot: eventRoot
        });

        vm.expectRevert("INVALID_START_BLOCK");
        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        ids.push(id);
        checkpointManager.submitBatch(ids, checkpoints, aggMessagePoints[8], validatorIds, validators);
    }

    function testCannotSubmitBatch_EmptyCheckpoint() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 1,
            eventRoot: eventRoot
        });

        vm.expectRevert("EMPTY_CHECKPOINT");
        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        ids.push(id);
        checkpointManager.submitBatch(ids, checkpoints, aggMessagePoints[9], validatorIds, validators);
    }

    function testCannotSubmitBatch_InvalidLength() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        vm.expectRevert("NOT_ENOUGH_SIGNATURES");
        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        ids.push(id);
        checkpointManager.submitBatch(
            ids,
            checkpoints,
            aggMessagePoints[10],
            new uint256[](0),
            new RootValidatorSet.Validator[](0)
        );
    }

    function testCannotSubmitBatch_InvalidSignature() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 102,
            eventRoot: eventRoot
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        ids.push(id);
        checkpointManager.submitBatch(ids, checkpoints, aggMessagePoints[11], validatorIds, validators);
    }

    function testSubmitBatch_WithoutValidators() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        CheckpointManager.Checkpoint memory checkpoint2 = CheckpointManager.Checkpoint({
            startBlock: 102,
            endBlock: 202,
            eventRoot: eventRoot
        });

        checkpoints.push(checkpoint1);
        checkpoints.push(checkpoint2);
        ids.push(id);
        ids.push(id + 1);

        uint256 currentValidatorIdBeforeSubmit = rootValidatorSet.currentValidatorId();
        checkpointManager.submitBatch(
            ids,
            checkpoints,
            aggMessagePoints[12],
            validatorIds,
            new RootValidatorSet.Validator[](0)
        );

        submitCounter = checkpointManager.currentCheckpointId() + 1;
        assertEq(submitCounter, 3);

        (, uint256 endBlock, ) = checkpointManager.checkpoints(submitCounter - 1);
        assertEq(endBlock, 202);
        startBlock = endBlock + 1;

        uint256 currentValidatorIdAfterSubmit = rootValidatorSet.currentValidatorId();
        assertEq(currentValidatorIdAfterSubmit, currentValidatorIdBeforeSubmit);
    }

    function testSubmitBatch_WithoutANewValidator() public {
        uint256 id = submitCounter;
        CheckpointManager.Checkpoint memory checkpoint1 = CheckpointManager.Checkpoint({
            startBlock: 1,
            endBlock: 101,
            eventRoot: eventRoot
        });

        CheckpointManager.Checkpoint memory checkpoint2 = CheckpointManager.Checkpoint({
            startBlock: 102,
            endBlock: 202,
            eventRoot: eventRoot
        });

        validators.push(newValidator);
        checkpoints.push(checkpoint1);
        checkpoints.push(checkpoint2);
        ids.push(id);
        ids.push(id + 1);

        uint256 currentValidatorIdBeforeSubmit = rootValidatorSet.currentValidatorId();
        checkpointManager.submitBatch(ids, checkpoints, aggMessagePoints[13], validatorIds, validators);

        submitCounter = checkpointManager.currentCheckpointId() + 1;
        assertEq(submitCounter, 3);

        (, uint256 endBlock, ) = checkpointManager.checkpoints(submitCounter - 1);
        assertEq(endBlock, 202);
        startBlock = endBlock + 1;

        uint256 currentValidatorIdAfterSubmit = rootValidatorSet.currentValidatorId();
        assertEq(currentValidatorIdAfterSubmit - 1, currentValidatorIdBeforeSubmit);

        RootValidatorSet.Validator memory validator = rootValidatorSet.getValidator(currentValidatorIdAfterSubmit);
        assertEq(keccak256(abi.encode(newValidator._address)), keccak256(abi.encode(validator._address)));
        assertEq(keccak256(abi.encode(newValidator.blsKey)), keccak256(abi.encode(validator.blsKey)));
    }
}
