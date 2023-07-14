// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "../common/Merkle.sol";
import "../interfaces/root/ICheckpointManager.sol";
import "../interfaces/common/IBLS.sol";
import "../interfaces/common/IBN256G2.sol";
import "../common/ValidatorSets.sol";

contract CheckpointManager is ICheckpointManager, ValidatorSets {
    using ArraysUpgradeable for uint256[];
    using Merkle for bytes32;

    uint256 public chainId;
    uint256 public currentEpoch;
    uint256 public currentCheckpointBlockNumber;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");

    mapping(uint256 => Checkpoint) public checkpoints; // epochId -> root
    uint256[] public checkpointBlockNumbers;

    /**
     * @notice Initialization function for CheckpointManager
     * @dev Contract can only be initialized once
     * @param newBls Address of the BLS library contract
     * @param newBn256G2 Address of the BLS library contract
     * @param chainId_ Chain ID of the child chain
     */
    function initialize(
        IBLS newBls,
        IBN256G2 newBn256G2,
        uint256 chainId_,
        Validator[] calldata newValidatorSet
    ) external initializer {
        super.initialize(newBls, newBn256G2, newValidatorSet);
        chainId = chainId_;
    }

    /**
     * @inheritdoc ICheckpointManager
     */
    function submit(
        CheckpointMetadata calldata checkpointMetadata,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        Validator[] calldata newValidatorSet,
        bytes calldata bitmap
    ) external {
        require(currentValidatorSetHash == checkpointMetadata.currentValidatorSetHash, "INVALID_VALIDATOR_SET_HASH");
        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    chainId,
                    checkpoint.blockNumber,
                    checkpointMetadata.blockHash,
                    checkpointMetadata.blockRound,
                    checkpoint.epoch,
                    checkpoint.eventRoot,
                    checkpointMetadata.currentValidatorSetHash,
                    keccak256(abi.encode(newValidatorSet))
                )
            )
        );

        _verifySignature(bls.hashToPoint(DOMAIN, hash), signature, bitmap);

        uint256 prevEpoch = currentEpoch;

        _verifyCheckpoint(prevEpoch, checkpoint);

        checkpoints[checkpoint.epoch] = checkpoint;

        if (checkpoint.epoch > prevEpoch) {
            // if new epoch, push new end block
            checkpointBlockNumbers.push(checkpoint.blockNumber);
            ++currentEpoch;
        } else {
            // update last end block if updating event root for epoch
            checkpointBlockNumbers[checkpointBlockNumbers.length - 1] = checkpoint.blockNumber;
        }

        currentCheckpointBlockNumber = checkpoint.blockNumber;

        _setNewValidatorSet(newValidatorSet);
    }

    /**
     * @inheritdoc ICheckpointManager
     */
    function getEventMembershipByBlockNumber(
        uint256 blockNumber,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 eventRoot = getEventRootByBlock(blockNumber);
        require(eventRoot != bytes32(0), "NO_EVENT_ROOT_FOR_BLOCK_NUMBER");
        return leaf.checkMembership(leafIndex, eventRoot, proof);
    }

    /**
     * @inheritdoc ICheckpointManager
     */
    function getEventMembershipByEpoch(
        uint256 epoch,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 eventRoot = checkpoints[epoch].eventRoot;
        require(eventRoot != bytes32(0), "NO_EVENT_ROOT_FOR_EPOCH");
        return leaf.checkMembership(leafIndex, eventRoot, proof);
    }

    /**
     * @inheritdoc ICheckpointManager
     */
    function getCheckpointBlock(uint256 blockNumber) external view returns (bool, uint256) {
        uint256 checkpointBlockIdx = checkpointBlockNumbers.findUpperBound(blockNumber);
        if (checkpointBlockIdx == checkpointBlockNumbers.length) {
            return (false, 0);
        }
        return (true, checkpointBlockNumbers[checkpointBlockIdx]);
    }

    /**
     * @inheritdoc ICheckpointManager
     */
    function getEventRootByBlock(uint256 blockNumber) public view returns (bytes32) {
        return checkpoints[checkpointBlockNumbers.findUpperBound(blockNumber) + 1].eventRoot;
    }

    /**
     * @notice Internal function that performs checks on the checkpoint
     * @param prevId Current checkpoint ID
     * @param checkpoint The checkpoint to store
     */
    function _verifyCheckpoint(uint256 prevId, Checkpoint calldata checkpoint) private view {
        Checkpoint memory oldCheckpoint = checkpoints[prevId];
        require(
            checkpoint.epoch == oldCheckpoint.epoch || checkpoint.epoch == (oldCheckpoint.epoch + 1),
            "INVALID_EPOCH"
        );
        require(checkpoint.blockNumber > oldCheckpoint.blockNumber, "EMPTY_CHECKPOINT");
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
