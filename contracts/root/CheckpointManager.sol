// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IBLS.sol";

contract CheckpointManager is Initializable {
    struct Checkpoint {
        uint256 startBlock;
        uint256 endBlock;
        bytes32 eventRoot;
    }

    uint256 public currentCheckpointId;
    bytes32 public domain;
    IBLS public bls;

    mapping(uint256 => Checkpoint) public checkpoints;

    function initialize(IBLS newBls, bytes32 newDomain) external initializer {
        bls = newBls;
        domain = newDomain;
    }

    function submit(
        uint256 id,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        uint256[4] calldata aggPubkey
    ) external {
        uint256 currentId = currentCheckpointId;
        require(id == currentId + 1, "ID_NOT_SEQUENTIAL");
        Checkpoint memory oldCheckpoint = checkpoints[currentId];
        require(
            oldCheckpoint.endBlock + 1 == checkpoint.startBlock,
            "INVALID_START_BLOCK"
        );
        require(
            checkpoint.endBlock > checkpoint.startBlock,
            "EMPTY_CHECKPOINT"
        );
        bytes memory hash = abi.encode(keccak256(abi.encode(id, checkpoint)));
        uint256[2] memory message = bls.hashToPoint(domain, hash);
        (bool callSuccess, bool result) = bls.verifySingle(
            signature,
            aggPubkey,
            message
        );
        require(callSuccess && result, "SIGNATURE_VERIFICATION_FAILED");
        checkpoints[currentCheckpointId++] = checkpoint;
    }
}
