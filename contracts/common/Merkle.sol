// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Merkle
 * @author Polygon Technology (similar to ENS, but written from scratch)
 * @notice library for checking membership in a merkle tree
 */
library Merkle {
    using Math for uint256;

    /**
     * @notice checks membership of a leaf in a merkle tree
     * @param leaf keccak256 hash to check the membership of
     * @param index position of the hash in the tree
     * @param rootHash root hash of the merkle tree
     * @param proof an array of hashes needed to prove the membership of the leaf
     * @return a boolean value indicating if the leaf is in the tree or not
     */
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        uint256 proofHeight = proof.length;
        // if the proof is of size n, the tree height will be n+1
        // in a tree of height n+1, max possible leaves are 2^n
        require(index < 2 ** proofHeight, "INVALID_LEAF_INDEX");
        // refuse to accept padded leaves as proof
        require(leaf != bytes32(0), "INVALID_LEAF");

        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proofHeight; ++i) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                // if index is even, proof must be to the right
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // if index is odd, proof is to the left
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            index /= 2;
        }
        return computedHash == rootHash;
    }

    /**
     * @notice checks membership of a leaf in a merkle tree with expected height
     * @param leaf keccak256 hash to check the membership of
     * @param index position of the hash in the tree
     * @param numLeaves number of leaves in the merkle tree (used to calculate the proof length)
     * @param rootHash root hash of the merkle tree
     * @param proof an array of hashes needed to prove the membership of the leaf
     * @return bool a boolean value indicating if the leaf is in the tree or not
     */
    function checkMembershipWithHeight(
        bytes32 leaf,
        uint256 index,
        uint256 numLeaves,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        uint256 proofHeight = proof.length;
        require(proofHeight == numLeaves.log2(Math.Rounding.Up), "INVALID_PROOF_LENGTH");
        // if the proof is of size n, the tree height will be n+1
        // in a tree of height n+1, max possible leaves are 2^n
        require(index < numLeaves, "INVALID_LEAF_INDEX");
        // refuse to accept padded leaves as proof
        require(leaf != bytes32(0), "INVALID_LEAF");

        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proofHeight; ++i) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                // if index is even, proof must be to the right
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // if index is odd, proof is to the left
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            index /= 2;
        }
        return computedHash == rootHash;
    }
}
