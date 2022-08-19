// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Merkle} from "contracts/common/Merkle.sol";

import "../utils/TestPlus.sol";

contract MerkleTest is TestPlus {
    using Merkle for bytes32;

    function testCannotCheckMemership_InvalidIndex(uint256 index, uint8 proofSize) public {
        index = bound(index, 2**proofSize, type(uint256).max);
        bytes32[] memory proof = new bytes32[](proofSize);

        vm.expectRevert("INVALID_LEAF_INDEX");
        this.checkMembershipHelper("", index, "", proof);
    }

    function testCheckMembership(
        bytes32[32] memory leaves,
        uint256 index,
        bytes32 randomHash
    ) public {
        // make hashes unique
        for (uint256 i; i < leaves.length; ++i) {
            leaves[i] = keccak256(abi.encode(leaves[i], i));
        }
        // bound index
        index %= leaves.length - 1;
        // get merkle root and proof from merkletreejs
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "test/forge/utils/merkle-root-proof";
        cmd[2] = vm.toString(abi.encode(leaves, index));
        (bytes32 root, bytes32[] memory proof) = abi.decode(vm.ffi(cmd), (bytes32, bytes32[]));

        assertTrue(this.checkMembershipHelper(leaves[index], index, root, proof));
        assertFalse(this.checkMembershipHelper(randomHash, index, root, proof));
    }

    /// @notice Helper for passing proof in calldata
    function checkMembershipHelper(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes32[] calldata proof
    ) external returns (bool) {
        return leaf.checkMembership(index, rootHash, proof);
    }
}
