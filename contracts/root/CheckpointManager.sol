// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IBLS.sol";

interface IRootValidatorSet {
    struct Validator {
        uint256 id;
        address _address;
        uint256[4] blsKey;
    }

    function validators(uint256 id) external returns (Validator memory);

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

    function submit(
        uint256 id,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        uint256[] calldata validatorIds
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
        uint256 length = validatorIds.length;
        // we assume here that length will always be more than 2 since validator set at genesis is larger than 6
        require(
            length > ((2 * rootValidatorSet.activeValidatorSetSize()) / 3),
            "NOT_ENOUGH_SIGNATURES"
        );
        uint256[4] memory aggPubkey = rootValidatorSet
            .validators(validatorIds[0])
            .blsKey;
        for (uint256 i = 1; i < length; ++i) {
            uint256[4] memory blsKey = rootValidatorSet
                .validators(validatorIds[i])
                .blsKey;
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
