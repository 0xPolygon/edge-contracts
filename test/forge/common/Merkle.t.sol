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

    function testCannotCheckMembership_InvalidIndex(uint256 index, uint8 proofSize) public {
        index = bound(index, 2 ** proofSize, type(uint256).max);
        bytes32[] memory proof = new bytes32[](proofSize);

        vm.expectRevert("INVALID_LEAF_INDEX");
        merkleUser.checkMembership("", index, "", proof);
    }

    function testCheckMembership(bytes32[] memory leaves, uint256 index) public {
        vm.assume(leaves.length > 1);
        // bound index
        index %= leaves.length - 1;
        // get merkle root and proof
        bytes32 root = getRoot(leaves);
        bytes32[] memory proof = getProof(leaves, index);
        bytes32 leaf = leaves[index];
        vm.assume(leaf != bytes32(0));
        bytes32 randomDataHash = keccak256(abi.encode(leaf));

        // should return true for leaf and false for random hash
        assertTrue(merkleUser.checkMembership(leaf, index, root, proof));
        assertFalse(merkleUser.checkMembership(randomDataHash, index, root, proof));
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
}
