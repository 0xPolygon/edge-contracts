// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IStateSender.sol";
import {IStateSender, IL2StateSender} from "../interfaces/IStateSender.sol";

/**
    @title L2StateSender
    @author Polygon Technology (@QEDK)
    @notice Arbitrary message passing contract from L2 -> L1
    @dev There is no transaction execution on L1, only a commitment of the emitted events are stored
 */
contract L2StateSender is IStateSender, IL2StateSender {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;
    Validator[] public validators;
    IL2StateSender.SignedMerkleRoot _latestSignedMerkleRoot;

    event L2StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);
    event ValidatorAdded(uint256[4] indexed validator);
    event ValidatorRemoved(uint256[4] indexed validator);

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

        emit L2StateSynced(++counter, msg.sender, receiver, data);
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

    function updateValidators(Validator[] memory _validators) external {
        // TODO: Verify signatures

        for (uint256 i = 0; i < _validators.length; i++) {
            Validator memory validator = _validators[i];
            if (validator.pubkey[0] == 0) {
                emit ValidatorRemoved(validator.pubkey);
            } else {
                emit ValidatorAdded(validator.pubkey);
            }
        }

        validators = _validators;
    }

    /**
     * @inheritdoc IBLS
     * TODO: Move to library
     */
    function verifyMultipleSameMsg(
        uint256[2] calldata signature,
        uint256[4][] calldata pubkeys,
        uint256[2] calldata message
    ) external view returns (bool checkResult, bool callSuccess) {
        uint256 size = pubkeys.length;
        // solhint-disable-next-line reason-string
        require(size > 0, "BLS: number of public key is zero");
        uint256 inputSize = (size + 1) * 6;
        uint256[] memory input = new uint256[](inputSize);
        input[0] = signature[0];
        input[1] = signature[1];
        input[2] = N_G2_X1;
        input[3] = N_G2_X0;
        input[4] = N_G2_Y1;
        input[5] = N_G2_Y0;
        for (uint256 i = 0; i < size; i++) {
            input[i * 6 + 6] = message[0];
            input[i * 6 + 7] = message[1];
            input[i * 6 + 8] = pubkeys[i][1];
            input[i * 6 + 9] = pubkeys[i][0];
            input[i * 6 + 10] = pubkeys[i][3];
            input[i * 6 + 11] = pubkeys[i][2];
        }
        uint256[1] memory out;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            callSuccess := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        if (!callSuccess) {
            return (false, false);
        }
        return (out[0] != 0, true);
    }
}
