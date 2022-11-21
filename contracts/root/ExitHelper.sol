// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface ICheckpointManager {
    function getEventMembershipByBlockNumber(
        uint256 blockNumber,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] calldata proof
    ) external view returns (bool);
}

/**
 * @title ExitHelper
 * @author @QEDK (Polygon Technology)
 * @notice Helper contract to process exits from stored event roots in CheckpointManager
 */
contract ExitHelper is Initializable {
    struct BatchExitInput {
        uint256 blockNumber;
        uint256 leafIndex;
        bytes unhashedLeaf;
        bytes32[] proof;
    }
    mapping(uint256 => bool) public processedExits;
    ICheckpointManager public checkpointManager;

    event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData);

    modifier onlyInitialized() {
        require(address(checkpointManager) != address(0), "ExitHelper: NOT_INITIALIZED");

        _;
    }

    /**
     * @notice Initialize the contract with the checkpoint manager address
     * @dev The checkpoint manager contract must be deployed first
     * @param newCheckpointManager Address of the checkpoint manager contract
     */
    function initialize(ICheckpointManager newCheckpointManager) external initializer {
        require(
            address(newCheckpointManager) != address(0) && address(newCheckpointManager).code.length != 0,
            "ExitHelper: INVALID_ADDRESS"
        );
        checkpointManager = newCheckpointManager;
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
    ) external onlyInitialized {
        _exit(blockNumber, leafIndex, unhashedLeaf, proof);
    }

    /**
     * @notice Perform a batch exit for multiple events
     * @param inputs Batch exit inputs for multiple event leaves
     */
    function batchExit(BatchExitInput[] calldata inputs) external onlyInitialized {
        uint256 length = inputs.length;

        for (uint256 i = 0; i < length; ) {
            _exit(inputs[i].blockNumber, inputs[i].leafIndex, inputs[i].unhashedLeaf, inputs[i].proof);
            unchecked {
                ++i;
            }
        }
    }

    function _exit(
        uint256 blockNumber,
        uint256 leafIndex,
        bytes calldata unhashedLeaf,
        bytes32[] calldata proof
    ) private {
        (uint256 id, address sender, address receiver, bytes memory data) = abi.decode(
            unhashedLeaf,
            (uint256, address, address, bytes)
        );
        require(
            checkpointManager.getEventMembershipByBlockNumber(blockNumber, keccak256(unhashedLeaf), leafIndex, proof),
            "ExitHelper: INVALID_PROOF"
        );

        bytes memory paramData = abi.encodeWithSignature("onL2StateReceive(uint256,address,bytes)", id, sender, data);

        (bool success, bytes memory returnData) = receiver.call(paramData);

        processedExits[id] = true;

        emit ExitProcessed(id, success, returnData);
    }
}
