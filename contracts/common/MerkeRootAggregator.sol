// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MerkleRootAggregator {
    struct MerkleRootNode {
        uint256 merkleRoot;
        uint256[2] aggregatedSignature;
        uint256 validatorSetIndex;
        bytes validatorBitmap;
    }

    MerkleRootNode _getLatestMerkleRoot;
}
