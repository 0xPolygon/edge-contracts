// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @title CheckpointManager
    @author Polygon Technology
    @notice Checkpoint manager contract used by validators to submit signed checkpoints as proof of canonical chain.
    @dev The contract is used to submit checkpoints and verify that they have been signed as expected.
    */
interface ICheckpointManager {
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

    /**
     * @notice Function to submit a single checkpoint for an epoch to CheckpointManager
     * @dev Contract internally verifies provided signature against stored validator set
     * @param checkpointMetadata The checkpoint metadata to verify with the signature
     * @param checkpoint The checkpoint to store
     * @param signature The aggregated signature submitted by the proposer
     * @param newValidatorSet The new validator set to store
     * @param bitmap The bitmap of the old valdiator set that signed the message
     */
    function submit(
        CheckpointMetadata calldata checkpointMetadata,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        Validator[] calldata newValidatorSet,
        bytes calldata bitmap
    ) external;

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
    ) external view returns (bool);

    /**
     * @notice Function to get if a event is part of the event root for an epoch
     * @param epoch The epoch id to get the event root for
     * @param leaf The leaf of the event (keccak256-encoded log)
     * @param leafIndex The leaf index of the event in the Merkle root tree
     * @param proof The proof for leaf membership in the event root tree
     */
    function getEventMembershipByEpoch(
        uint256 epoch,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] calldata proof
    ) external view returns (bool);

    /**
     * @notice Function to get the checkpoint block number for a block number.
     * It finds block number which is greater or equal than provided one in checkpointBlockNumbers array.
     * @param blockNumber The block number to get the checkpoint block number for
     * @return bool If block number was checkpointed
     * @return uint256 The checkpoint block number
     */
    function getCheckpointBlock(uint256 blockNumber) external view returns (bool, uint256);

    /**
     * @notice Function to get the event root for a block number
     * @param blockNumber The block number to get the event root for
     */
    function getEventRootByBlock(uint256 blockNumber) external view returns (bytes32);
}
