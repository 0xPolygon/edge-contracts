// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "../common/Merkle.sol";
import "../interfaces/IBLS.sol";
import "hardhat/console.sol";

interface IBN256G2 {
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

/**
    @title CheckpointManager
    @author Polygon Technology
    @notice Checkpoint manager contract used by validators to submit signed checkpoints as proof of canonical chain.
    @dev The contract is used to submit checkpoints and verify that they have been signed as expected.
    */
contract CheckpointManager is Initializable {
    using ArraysUpgradeable for uint256[];
    using Merkle for bytes32;

    struct Checkpoint {
        uint256 epoch;
        uint256 blockNumber;
        bytes32 eventRoot;
    }

    struct CheckpointMetadata {
        bytes32 blockHash;
        uint256 blockRound;
        bytes32 currentValidatorSetHash;
    }

    struct Validator {
        address _address;
        uint256[4] blsKey;
        uint256 votingPower;
    }

    uint256 public currentEpoch;
    uint256 public currentValidatorSetLength;
    bytes32 public domain;
    IBLS public bls;
    IBN256G2 public bn256G2;

    mapping(uint256 => Checkpoint) public checkpoints; // epochId -> root
    mapping(uint256 => Validator) public currentValidatorSet;
    uint256[] public checkpointBlockNumbers;

    /**
     * @notice Initialization function for CheckpointManager
     * @dev Contract can only be initialized once
     * @param newBls Address of the BLS library contract
     * @param newBn256G2 Address of the BLS library contract
     * @param newDomain Domain to use when hashing messages to a point
     */
    function initialize(
        IBLS newBls,
        IBN256G2 newBn256G2,
        bytes32 newDomain,
        Validator[] calldata newValidatorSet
    ) external initializer {
        bls = newBls;
        bn256G2 = newBn256G2;
        domain = newDomain;
        currentValidatorSetLength = newValidatorSet.length;
        _setNewValidatorSet(newValidatorSet);
    }

    /**
     * @notice Function to submit a single checkpoint for an epoch to CheckpointManager
     * @dev Contract internally verifies provided signature against stored validator set
     * @param chainId The chain ID of the checkpoint being signed
     * @param checkpointMetadata The checkpoint metadata to verify with the signature
     * @param checkpoint The checkpoint to store
     * @param signature The aggregated signature submitted by the proposer
     * @param newValidatorSet The new validator set to store
     * @param bitmap The bitmap of the old valdiator set that signed the message
     */
    function submit(
        uint256 chainId,
        CheckpointMetadata calldata checkpointMetadata,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        Validator[] calldata newValidatorSet,
        bytes calldata bitmap
    ) external {
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

        // slither-disable-next-line reentrancy-benign
        require(_verifySignature(bls.hashToPoint(domain, hash), signature, bitmap), "SIGNATURE_VERIFICATION_FAILED");

        uint256 prevEpoch = currentEpoch++;

        _verifyCheckpoint(prevEpoch, checkpoint);

        checkpoints[checkpoint.epoch] = checkpoint;

        if (checkpoint.epoch > prevEpoch) {
            // if new epoch, push new end block
            checkpointBlockNumbers.push(checkpoint.blockNumber);
        } else {
            // update last end block if updating event root for epoch
            if (checkpointBlockNumbers.length > 0)
                checkpointBlockNumbers[checkpointBlockNumbers.length - 1] = checkpoint.blockNumber;
            else checkpointBlockNumbers[0] = checkpoint.blockNumber;
        }

        _setNewValidatorSet(newValidatorSet);
    }

    /**
     * @notice Function to get if a event is part of the event root for a block number
     * @param blockNumber The block number to get the event root from (i.e. blockN <-- eventRoot --> blockN+M)
     * @param leaf The leaf of the event (keccak256-encoded log)
     * @param leafIndex The leaf index of the event in the Merkle root tree
     * @param proof The proof for leaf membership in the event root tree
     */
    function getEventMembershipByBlockNumber(
        uint256 blockNumber,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 eventRoot = getEventRootByBlock(blockNumber);
        require(eventRoot != bytes32(0), "CheckpointManager: NO_EVENT_ROOT_FOR_BLOCK_NUMBER");
        return leaf.checkMembership(leafIndex, eventRoot, proof);
    }

    /**
     * @notice Function to get if a event is part of the event root for an epoch
     * @param checkpointId The checkpoint id to get the event root from
     * @param leaf The leaf of the event (keccak256-encoded log)
     * @param leafIndex The leaf index of the event in the Merkle root tree
     * @param proof The proof for leaf membership in the event root tree
     */
    function getEventMembershipByEpoch(
        uint256 checkpointId,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 eventRoot = checkpoints[checkpointId].eventRoot;
        require(eventRoot != bytes32(0), "CheckpointManager: NO_EVENT_ROOT_FOR_EPOCH");
        return leaf.checkMembership(leafIndex, eventRoot, proof);
    }

    /**
     * @notice Function to get the event root for a block number
     * @param blockNumber The block number to get the event root for
     */
    function getEventRootByBlock(uint256 blockNumber) public view returns (bytes32) {
        console.log(checkpointBlockNumbers.findUpperBound(blockNumber));
        return checkpoints[checkpointBlockNumbers.findUpperBound(blockNumber)].eventRoot;
    }

    function _setNewValidatorSet(Validator[] calldata newValidatorSet) private {
        uint256 length = newValidatorSet.length;
        currentValidatorSetLength = length;
        for (uint256 i = 0; i < length; ++i) {
            currentValidatorSet[i] = newValidatorSet[i];
        }
    }

    /**
     * @notice Internal function that performs checks on the checkpoint
     * @param prevId Current checkpoint ID
     * @param checkpoint The checkpoint to store
     */
    function _verifyCheckpoint(uint256 prevId, Checkpoint calldata checkpoint) internal view {
        Checkpoint memory oldCheckpoint = checkpoints[prevId];
        require(checkpoint.epoch >= oldCheckpoint.epoch, "CheckpointManager: INVALID_EPOCH");
        require(checkpoint.blockNumber > oldCheckpoint.blockNumber, "CheckpointManager: EMPTY_CHECKPOINT");
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
    ) private view returns (bool) {
        uint256 length = currentValidatorSetLength;
        uint256[4] memory aggPubkey;
        uint256 firstIndex = 0;
        bool flag = false;
        for (uint256 i = 0; i < length; ++i) {
            if (_getValueFromBitmap(bitmap, i)) {
                aggPubkey = currentValidatorSet[i].blsKey;
                firstIndex = i;
                flag = true;
                break;
            }
        }
        require(flag, "CheckpointManager: BITMAP_IS_EMPTY");
        uint256 aggVotingPower = 0;
        flag = false;
        for (uint256 i = firstIndex + 1; i < length; ++i) {
            if (_getValueFromBitmap(bitmap, i)) {
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
                aggVotingPower += currentValidatorSet[i].votingPower;
            } else {
                continue;
            }
            // if voting power >= 67%, checkpoint is accepted
            if ((aggVotingPower / (10**18)) > 66) {
                flag = true;
                break;
            }
        }

        require(flag, "CheckpointManager: INSUFFICIENT_VOTING_POWER");

        (bool callSuccess, bool result) = bls.verifySingle(signature, aggPubkey, message);

        return callSuccess && result;
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
