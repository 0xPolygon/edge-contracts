// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Merkle
 * @author QEDK
 * @notice Gas optimized verification of proof of inclusion for a leaf in an ordered Merkle tree
 */
library Merkle {
    /**
     * @notice checks membership of a leaf in a merkle tree
     * @param leaf keccak256 hash to check the membership of
     * @param index position of the hash in the tree
     * @param rootHash root hash of the merkle tree
     * @param proof an array of hashes needed to prove the membership of the leaf
     * @return isMember boolean value indicating if the leaf is in the tree or not
     */
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) internal pure returns (bool isMember) {
        // solhint-disable-next-line no-inline-assembly
        // slither-disable-next-line assembly
        assembly ("memory-safe") {
            // if proof is empty, check if the leaf is the root
            if proof.length {
                // set end to be the end of the proof array, shl(5, proof.length) is equivalent to proof.length * 32
                let end := add(proof.offset, shl(5, proof.length))
                // set iterator to the start of the proof array
                let i := proof.offset
                // prettier-ignore
                // solhint-disable-next-line no-empty-blocks
                for {} 1 {} {
                    // if index is odd, leaf slot is at 0x20, else 0x0
                    let leafSlot := shl(5, and(0x1, index))
                    // store the leaf at the calculated slot
                    mstore(leafSlot, leaf)
                    // store proof element in whichever slot is not occupied by the leaf
                    mstore(xor(leafSlot, 32), calldataload(i))
                    // hash the first 64 bytes in memory
                    leaf := keccak256(0, 64)
                    // shift index right by 1 bit to divide by 2
                    index := shr(1, index)
                    // increment iterator by 32 bytes
                    i := add(i, 32)
                    // break if iterator is at the end of the proof array
                    if iszero(lt(i, end)) {
                        break
                    }
                }
            }
            // checks if the calculated root matches the expected root
            // then, check if index was zeroed while calculating proof, else an invalid index was provided
            isMember := and(eq(leaf, rootHash), iszero(index))
        }
    }

    /**
     * @notice checks membership of a leaf in a merkle tree with expected height
     * @param leaf keccak256 hash to check the membership of
     * @param index position of the hash in the tree
     * @param numLeaves number of leaves in the merkle tree (used to check the proof length)
     * @param rootHash root hash of the merkle tree
     * @param proof an array of hashes needed to prove the membership of the leaf
     * @return isMember a boolean value indicating if the leaf is in the tree or not
     */
    function checkMembershipWithHeight(
        bytes32 leaf,
        uint256 index,
        uint256 numLeaves,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) internal pure returns (bool isMember) {
        // solhint-disable-next-line no-inline-assembly
        // slither-disable-next-line assembly
        assembly ("memory-safe") {
            // if proof is empty, check if the leaf is the root
            if proof.length {
                // set end to be the end of the proof array, shl(5, proof.length) is equivalent to proof.length * 32
                let end := add(proof.offset, shl(5, proof.length))
                // set iterator to the start of the proof array
                let i := proof.offset
                // prettier-ignore
                // solhint-disable-next-line no-empty-blocks
                for {} 1 {} {
                    // if index is odd, leaf slot is at 0x20, else 0x0
                    let leafSlot := shl(5, and(0x1, index))
                    // store the leaf at the calculated slot
                    mstore(leafSlot, leaf)
                    // store proof element in whichever slot is not occupied by the leaf
                    mstore(xor(leafSlot, 32), calldataload(i))
                    // hash the first 64 bytes in memory
                    leaf := keccak256(0, 64)
                    // shift index right by 1 bit to divide by 2
                    index := shr(1, index)
                    // increment iterator by 32 bytes
                    i := add(i, 32)
                    // break if iterator is at the end of the proof array
                    if iszero(lt(i, end)) {
                        break
                    }
                }
            }
            // check if log2(numLeaves) is an integer, or else rounds up to the next integer
            // then, checks if the calculated root matches the expected root
            // finally, checks if index was zeroed while calculating proof, else an invalid index was provided
            // slither-disable-next-line incorrect-shift
            isMember := and(
                and(lt(numLeaves, add(shl(proof.length, 0x1), 1)), gt(numLeaves, shl(sub(proof.length, 1), 0x1))),
                and(eq(leaf, rootHash), iszero(index))
            )
        }
    }
}
