// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "../common/Merkle.sol";
import "../interfaces/root/ICheckpointManager.sol";
import "../interfaces/common/IBLS.sol";
import "../interfaces/common/IBN256G2.sol";

contract CheckpointManager is ICheckpointManager, Initializable {
    using ArraysUpgradeable for uint256[];
    using Merkle for bytes32;

    uint256 public chainId;
    uint256 public currentEpoch;
    uint256 public currentValidatorSetLength;
    uint256 public currentCheckpointBlockNumber;
    uint256 public totalVotingPower;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    IBLS public bls;
    IBN256G2 public bn256G2;

    mapping(uint256 => Checkpoint) public checkpoints; // epochId -> root
    mapping(uint256 => Validator) public currentValidatorSet;
    uint256[] public checkpointBlockNumbers;
    bytes32 public currentValidatorSetHash;

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
        chainId = chainId_;
        bls = newBls;
        bn256G2 = newBn256G2;
        currentValidatorSetLength = newValidatorSet.length;
        _setNewValidatorSet(newValidatorSet);
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

    function _setNewValidatorSet(Validator[] calldata newValidatorSet) private {
        uint256 length = newValidatorSet.length;
        currentValidatorSetLength = length;
        currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;
        for (uint256 i = 0; i < length; ++i) {
            uint256 votingPower = newValidatorSet[i].votingPower;
            require(votingPower > 0, "VOTING_POWER_ZERO");
            totalPower += votingPower;
            currentValidatorSet[i] = newValidatorSet[i];
        }
        totalVotingPower = totalPower;
    }

    /**
     * @notice Internal function that asserts that the signature is valid and that the required threshold is met
     * @param message The message that was signed by validators (i.e. checkpoint hash)
     * @param signature The aggregated signature submitted by the proposer
     */
    function _verifySignature(
        uint256[2] memory message,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) private view {
        uint256 length = currentValidatorSetLength;
        // slither-disable-next-line uninitialized-local
        uint256[4] memory aggPubkey;
        uint256 aggVotingPower = 0;
        for (uint256 i = 0; i < length; ) {
            if (_getValueFromBitmap(bitmap, i)) {
                if (aggVotingPower == 0) {
                    aggPubkey = currentValidatorSet[i].blsKey;
                } else {
                    uint256[4] memory blsKey = currentValidatorSet[i].blsKey;
                    // slither-disable-next-line calls-loop
                    (aggPubkey[0], aggPubkey[1], aggPubkey[2], aggPubkey[3]) = bn256G2.ecTwistAdd(
                        aggPubkey[0],
                        aggPubkey[1],
                        aggPubkey[2],
                        aggPubkey[3],
                        blsKey[0],
                        blsKey[1],
                        blsKey[2],
                        blsKey[3]
                    );
                }
                aggVotingPower += currentValidatorSet[i].votingPower;
            }
            unchecked {
                ++i;
            }
        }

        require(aggVotingPower != 0, "BITMAP_IS_EMPTY");
        require(aggVotingPower > ((2 * totalVotingPower) / 3), "INSUFFICIENT_VOTING_POWER");

        (bool callSuccess, bool result) = bls.verifySingle(signature, aggPubkey, message);

        require(callSuccess && result, "SIGNATURE_VERIFICATION_FAILED");
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

    function _getValueFromBitmap(bytes calldata bitmap, uint256 index) private pure returns (bool) {
        uint256 byteNumber = index / 8;
        uint8 bitNumber = uint8(index % 8);

        if (byteNumber >= bitmap.length) {
            return false;
        }

        // Get the value of the bit at the given 'index' in a byte.
        return uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0;
    }
}
