// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Merkle} from "contracts/common/Merkle.sol";

import "../utils/TestPlus.sol";
import {MurkyBase} from "murky/common/MurkyBase.sol";

contract MerkleTest is TestPlus, MurkyBase {
    using Merkle for bytes32;

    /// @notice Hashing function for Murky
    function hashLeafPairs(bytes32 left, bytes32 right) public pure override returns (bytes32 _hash) {
        _hash = keccak256(abi.encode(left, right));
    }

    function testCannotCheckMemership_InvalidIndex(uint256 index, uint8 proofSize) public {
        index = bound(index, 2**proofSize, type(uint256).max);
        bytes32[] memory proof = new bytes32[](proofSize);

        vm.expectRevert("INVALID_LEAF_INDEX");
        this.checkMembershipHelper("", index, "", proof);
    }

    function testCheckMembership(bytes32[] memory leaves, uint256 index) public {
        vm.assume(leaves.length > 1);
        // bound index
        index %= leaves.length - 1;
        // get merkle root and proof
        bytes32 root = getRoot(leaves);
        bytes32[] memory proof = getProof(leaves, index);
        bytes32 leaf = leaves[index];
        bytes32 randomDataHash = keccak256(abi.encode(leaf));

        // should return true for leaf and false for random hash
        assertTrue(this.checkMembershipHelper(leaf, index, root, proof));
        assertFalse(this.checkMembershipHelper(randomDataHash, index, root, proof));
    }

    /// @notice Helper for passing proof in calldata
    function checkMembershipHelper(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) external view returns (bool) {
        return leaf.checkMembership(index, rootHash, proof);
    }
}