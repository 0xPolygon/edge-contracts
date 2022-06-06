pragma solidity ^0.8.13;

import "hardhat/console.sol";

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        uint256 proofHeight = proof.length;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "INVALID_LEAF_INDEX");

        bytes32 computedHash = leaf;
        console.logBytes32(leaf);
        for (uint256 i = 0; i < proofHeight; ++i) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
                console.log("mod2");
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
                console.log("mod1");
            }
            console.logBytes32(computedHash);
            index /= 2;
        }
        console.logBytes32(computedHash);
        console.logBytes32(rootHash);
        return computedHash == rootHash;
    }
}
