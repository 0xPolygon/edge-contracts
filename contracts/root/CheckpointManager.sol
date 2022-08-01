// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IBLS.sol";

interface IRootValidatorSet {
    struct Validator {
        address _address;
        uint256[4] blsKey;
    }

    function addValidators(Validator[] calldata newValidators) external;

    function getValidatorBlsKey(uint256 id)
        external
        view
        returns (uint256[4] memory);

    function activeValidatorSetSize() external returns (uint256);
}

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
    struct Checkpoint {
        uint256 startBlock;
        uint256 endBlock;
        bytes32 eventRoot;
    }

    uint256 public currentCheckpointId;
    bytes32 public domain;
    IBLS public bls;
    IBN256G2 public bn256G2;
    IRootValidatorSet public rootValidatorSet;

    mapping(uint256 => Checkpoint) public checkpoints;

    /**
     * @notice Initialization function for CheckpointManager
     * @dev Contract can only be initialized once
     * @param newBls Address of the BLS library contract
     * @param newBn256G2 Address of the BLS library contract
     * @param newRootValidatorSet Array of validator addresses to seed the contract with
     * @param newDomain Domain to use when hashing messages to a point
     */
    function initialize(
        IBLS newBls,
        IBN256G2 newBn256G2,
        IRootValidatorSet newRootValidatorSet,
        bytes32 newDomain
    ) external initializer {
        bls = newBls;
        bn256G2 = newBn256G2;
        rootValidatorSet = newRootValidatorSet;
        domain = newDomain;
    }

    /**
     * @notice Function to submit a single checkpoint to CheckpointManager
     * @dev Contract internally verifies provided signature against stored validator set
     * @param id ID of the checkpoint
     * @param checkpoint The checkpoint to store
     * @param signature The aggregated signature submitted by proposer
     * @param validatorIds Array of the IDs of validators who have signed the checkpoint
     */
    function submit(
        uint256 id,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        uint256[] calldata validatorIds,
        IRootValidatorSet.Validator[] calldata newValidators
    ) external {
        bytes memory hash = abi.encode(
            keccak256(abi.encode(id, checkpoint, newValidators))
        );

        uint256[2] memory message = bls.hashToPoint(domain, hash);

        // slither-disable-next-line reentrancy-benign
        require(
            _verifySignature(message, signature, validatorIds),
            "SIGNATURE_VERIFICATION_FAILED"
        );

        _verifyCheckpoint(currentCheckpointId, id, checkpoint);

        checkpoints[++currentCheckpointId] = checkpoint;

        if (newValidators.length != 0) {
            rootValidatorSet.addValidators(newValidators);
        }
    }

    /**
     * @notice Function to submit a batch of checkpoints to CheckpointManager
     * @dev Contract internally verifies provided signature against stored validator set
     * @param ids IDs of the checkpoint batch
     * @param checkpointBatch The checkpoint batch to store
     * @param signature The aggregated signature submitted by the proposer
     * @param validatorIds Array of the IDs of validators who have signed the checkpoint
     */
    function submitBatch(
        uint256[] calldata ids,
        Checkpoint[] calldata checkpointBatch,
        uint256[2] calldata signature,
        uint256[] calldata validatorIds,
        IRootValidatorSet.Validator[] calldata newValidators
    ) external {
        bytes memory hash = abi.encode(
            keccak256(abi.encode(ids, checkpointBatch, newValidators))
        );

        // slither-disable-next-line reentrancy-benign
        require(
            _verifySignature(
                bls.hashToPoint(domain, hash),
                signature,
                validatorIds
            ),
            "SIGNATURE_VERIFICATION_FAILED"
        );

        uint256 length = ids.length;

        require(length == checkpointBatch.length, "LENGTH_MISMATCH");

        uint256 prevId = currentCheckpointId;

        for (uint256 i = 0; i < length; ++i) {
            _verifyCheckpoint(prevId++, ids[i], checkpointBatch[i]);
            checkpoints[ids[i]] = checkpointBatch[i];
        }

        currentCheckpointId = prevId;

        if (newValidators.length != 0) {
            rootValidatorSet.addValidators(newValidators);
        }
    }

    /**
     * @notice Internal function that performs checks on the checkpoint
     * @param prevId Current checkpoint ID
     * @param id ID of the checkpoint
     * @param checkpoint The checkpoint to store
     */
    function _verifyCheckpoint(
        uint256 prevId,
        uint256 id,
        Checkpoint calldata checkpoint
    ) internal view {
        require(id == prevId + 1, "ID_NOT_SEQUENTIAL");
        Checkpoint memory oldCheckpoint = checkpoints[prevId];
        require(
            oldCheckpoint.endBlock + 1 == checkpoint.startBlock,
            "INVALID_START_BLOCK"
        );
        require(
            checkpoint.endBlock > checkpoint.startBlock,
            "EMPTY_CHECKPOINT"
        );
    }

    /**
     * @notice Internal function that asserts that the signature is valid and that the required threshold is met
     * @param message The message that was signed by validators (i.e. checkpoint hash)
     * @param signature The aggregated signature submitted by the proposer
     * @param validatorIds Array of the IDs of validators who have signed the checkpoint
     */
    function _verifySignature(
        uint256[2] memory message,
        uint256[2] calldata signature,
        uint256[] calldata validatorIds
    ) internal returns (bool) {
        uint256 length = validatorIds.length;
        // we assume here that length will always be more than 2 since validator set at genesis is larger than 6
        require(
            length > ((2 * rootValidatorSet.activeValidatorSetSize()) / 3),
            "NOT_ENOUGH_SIGNATURES"
        );
        uint256[4] memory aggPubkey = rootValidatorSet.getValidatorBlsKey(
            validatorIds[0]
        );
        for (uint256 i = 1; i < length; ++i) {
            uint256[4] memory blsKey = rootValidatorSet.getValidatorBlsKey(
                validatorIds[i]
            );
            // slither-disable-next-line calls-loop
            (aggPubkey[0], aggPubkey[1], aggPubkey[2], aggPubkey[3]) = bn256G2
                .ecTwistAdd(
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

        (bool callSuccess, bool result) = bls.verifySingle(
            signature,
            aggPubkey,
            message
        );

        return callSuccess && result;
    }
}
