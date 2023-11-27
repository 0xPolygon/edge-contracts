// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title ExitHelper
 * @author @QEDK (Polygon Technology)
 * @notice Helper contract to process exits from stored event roots in CheckpointManager
 */
interface IExitHelper {
    struct BatchExitInput {
        uint256 blockNumber;
        uint256 leafIndex;
        bytes unhashedLeaf;
        bytes32[] proof;
    }

    /**
     * @notice Perform an exit for one event
     * @param blockNumber Block number of the exit event on L2
     * @param leafIndex Index of the leaf in the exit event Merkle tree
     * @param unhashedLeaf ABI-encoded exit event leaf
     * @param proof Proof of the event inclusion in the tree
     */
    function exit(
        uint256 blockNumber,
        uint256 leafIndex,
        bytes calldata unhashedLeaf,
        bytes32[] calldata proof
    ) external;

    /**
     * @notice Perform a batch exit for multiple events
     * @param inputs Batch exit inputs for multiple event leaves
     */
    function batchExit(BatchExitInput[] calldata inputs) external;
}
