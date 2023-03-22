// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/root/ICheckpointManager.sol";
import "../interfaces/root/IExitHelper.sol";

contract ExitHelper is IExitHelper, Initializable {
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
     * @inheritdoc IExitHelper
     */
    function exit(
        uint256 blockNumber,
        uint256 leafIndex,
        bytes calldata unhashedLeaf,
        bytes32[] calldata proof
    ) external onlyInitialized {
        _exit(blockNumber, leafIndex, unhashedLeaf, proof, false);
    }

    /**
     * @inheritdoc IExitHelper
     */
    function batchExit(BatchExitInput[] calldata inputs) external onlyInitialized {
        uint256 length = inputs.length;

        for (uint256 i = 0; i < length; ) {
            _exit(inputs[i].blockNumber, inputs[i].leafIndex, inputs[i].unhashedLeaf, inputs[i].proof, true);
            unchecked {
                ++i;
            }
        }
    }

    function _exit(
        uint256 blockNumber,
        uint256 leafIndex,
        bytes calldata unhashedLeaf,
        bytes32[] calldata proof,
        bool isBatch
    ) private {
        (uint256 id, address sender, address receiver, bytes memory data) = abi.decode(
            unhashedLeaf,
            (uint256, address, address, bytes)
        );
        if (isBatch) {
            if (processedExits[id]) {
                return;
            }
        } else {
            require(!processedExits[id], "ExitHelper: EXIT_ALREADY_PROCESSED");
        }

        // slither-disable-next-line calls-loop
        require(
            checkpointManager.getEventMembershipByBlockNumber(blockNumber, keccak256(unhashedLeaf), leafIndex, proof),
            "ExitHelper: INVALID_PROOF"
        );

        processedExits[id] = true;

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-events,reentrancy-no-eth
        (bool success, bytes memory returnData) = receiver.call(
            abi.encodeWithSignature("onL2StateReceive(uint256,address,bytes)", id, sender, data)
        );

        // if state sync fails, revert flag
        if (!success) processedExits[id] = false;

        emit ExitProcessed(id, success, returnData);
    }
}
