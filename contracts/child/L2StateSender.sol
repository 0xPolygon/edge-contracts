// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IStateSender.sol";
import "../common/MerkeRootAggregator.sol";

/**
    @title L2StateSender
    @author Polygon Technology (@QEDK)
    @notice Arbitrary message passing contract from L2 -> L1
    @dev There is no transaction execution on L1, only a commitment of the emitted events are stored
 */
contract L2StateSender is IStateSender, MerkleRootAggregator {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;

    event L2StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    /**
     * @notice Emits an event which is indexed by v3 validators and submitted as a commitment on L1
     * allowing for lazy execution
     * @param receiver Address of the message recipient on L1
     * @param data Data to use in message call to recipient
     */
    function syncState(address receiver, bytes calldata data) external {
        // check receiver
        require(receiver != address(0), "INVALID_RECEIVER");
        // check data length
        require(data.length <= MAX_LENGTH, "EXCEEDS_MAX_LENGTH");

        uint256 newCounter = ++counter;
        emit L2StateSynced(newCounter, msg.sender, receiver, data);

        addLeaf(keccak256(abi.encodePacked(newCounter, msg.sender, receiver, data)));
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;

    // ===========================================
    // TODO: clean this up, messy code
    // State variables
    uint constant STATE_SENDER_TREE_DEPTH = 32;
    // NOTE: this also ensures `event_count` will fit into 64-bits
    uint constant MAX_LEAF_COUNT = 2 ** STATE_SENDER_TREE_DEPTH - 1;

    bytes32[STATE_SENDER_TREE_DEPTH] branch;
    uint256 event_count;

    bytes32[STATE_SENDER_TREE_DEPTH] zero_hashes;

    // Constructor
    constructor() {
        // Compute hashes in empty sparse Merkle tree
        for (uint height = 0; height < STATE_SENDER_TREE_DEPTH - 1; height++)
            zero_hashes[height + 1] = sha256(abi.encodePacked(zero_hashes[height], zero_hashes[height]));
    }

    // View functions
    function getRoot() external view returns (bytes32) {
        bytes32 node;
        uint size = event_count;
        for (uint height = 0; height < STATE_SENDER_TREE_DEPTH; height++) {
            if ((size & 1) == 1) node = sha256(abi.encodePacked(branch[height], node));
            else node = sha256(abi.encodePacked(node, zero_hashes[height]));
            size /= 2;
        }
        return sha256(abi.encodePacked(node, to_little_endian_64(uint64(event_count)), bytes24(0)));
    }

    function get_event_count() external view returns (bytes memory) {
        return to_little_endian_64(uint64(event_count));
    }

    // Internal functions
    function addLeaf(bytes32 node) internal {
        // Avoid overflowing the Merkle tree (and prevent edge case in computing `branch`)
        require(event_count < MAX_LEAF_COUNT, "L2StateSender: merkle tree full");

        // Add deposit data root to Merkle tree (update a single `branch` node)
        event_count += 1;
        uint size = event_count;
        for (uint height = 0; height < STATE_SENDER_TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                branch[height] = node;
                return;
            }
            node = sha256(abi.encodePacked(branch[height], node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
}
