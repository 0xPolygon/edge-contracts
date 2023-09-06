// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {MurkyBase} from "murky/common/MurkyBase.sol";

import {Merkle} from "contracts/common/Merkle.sol";

contract MerkleTest is Test, MurkyBase {
    MerkleUser merkleUser;

    function setUp() public {
        merkleUser = new MerkleUser();
    }

    /// @notice Hashing function for Murky
    function hashLeafPairs(bytes32 left, bytes32 right) public pure override returns (bytes32 _hash) {
        _hash = keccak256(abi.encode(left, right));
    }

    function testCheckMembershipSingleLeaf(bytes32 leaf, uint256 index) public {
        vm.assume(index != 0);
        bytes32 randomDataHash = keccak256(abi.encode(leaf));
        bytes32[] memory proof = new bytes32[](0);

        // should return true for leaf and false for random hash
        assertTrue(merkleUser.checkMembership(leaf, 0, leaf, proof));
        assertFalse(merkleUser.checkMembership(randomDataHash, 0, leaf, proof));
        assertFalse(merkleUser.checkMembership(leaf, index, leaf, proof));
    }

    function testCheckMembership(bytes32[] memory leaves, uint256 index) public {
        vm.assume(leaves.length > 1);
        vm.assume(index < leaves.length);
        bytes32 root = getRoot(leaves);
        bytes32[] memory proof = getProof(leaves, index);
        bytes32 leaf = leaves[index];
        bytes32 randomDataHash = keccak256(abi.encode(leaf));

        // should return true for leaf and false for random hash
        assertTrue(merkleUser.checkMembership(leaf, index, root, proof));
        assertFalse(merkleUser.checkMembership(randomDataHash, index, root, proof));
        assertFalse(merkleUser.checkMembership(leaf, leaves.length, root, proof));
    }

    function testCheckMembershiLargeTree(bytes32[] memory leaves, uint256 index) public {
        vm.assume(leaves.length > 128);
        vm.assume(index < leaves.length);
        bytes32 root = getRoot(leaves);
        bytes32[] memory proof = getProof(leaves, index);
        bytes32 leaf = leaves[index];
        bytes32 randomDataHash = keccak256(abi.encode(leaf));

        // should return true for leaf and false for random hash
        assertTrue(merkleUser.checkMembership(leaf, index, root, proof));
        assertFalse(merkleUser.checkMembership(randomDataHash, index, root, proof));
        assertFalse(merkleUser.checkMembership(leaf, leaves.length, root, proof));
    }

    function testCheckMembershipWithHeight(bytes32[] memory leaves, uint256 index) public {
        vm.assume(leaves.length > 1);
        vm.assume(index < leaves.length);
        bytes32 root = getRoot(leaves);
        bytes32[] memory proof = getProof(leaves, index);
        bytes32 leaf = leaves[index];
        bytes32 randomDataHash = keccak256(abi.encode(leaf));

        // should return true for leaf and false for random hash
        assertTrue(merkleUser.checkMembershipWithHeight(leaf, index, leaves.length, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(randomDataHash, index, leaves.length, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, leaves.length, leaves.length, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, index, (2 ** proof.length) + 1, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, index, (2 ** (proof.length - 1)), root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, leaves.length, (2 ** (proof.length - 1)), root, proof));
    }

    function testCheckMembershipWithHeightLargeTree(bytes32[] memory leaves, uint256 index) public {
        vm.assume(leaves.length > 128);
        vm.assume(index < leaves.length);
        bytes32 root = getRoot(leaves);
        bytes32[] memory proof = getProof(leaves, index);
        bytes32 leaf = leaves[index];
        bytes32 randomDataHash = keccak256(abi.encode(leaf));

        // should return true for leaf and false for random hash
        assertTrue(merkleUser.checkMembershipWithHeight(leaf, index, leaves.length, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(randomDataHash, index, leaves.length, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, leaves.length, leaves.length, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, index, (2 ** proof.length) + 1, root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, index, (2 ** (proof.length - 1)), root, proof));
        assertFalse(merkleUser.checkMembershipWithHeight(leaf, leaves.length, (2 ** (proof.length - 1)), root, proof));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract MerkleUser {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) external pure returns (bool) {
        bool r = Merkle.checkMembership(leaf, index, rootHash, proof);
        return r;
    }

    function checkMembershipWithHeight(
        bytes32 leaf,
        uint256 index,
        uint256 numLeaves,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) external pure returns (bool) {
        bool r = Merkle.checkMembershipWithHeight(leaf, index, numLeaves, rootHash, proof);
        return r;
    }
}
