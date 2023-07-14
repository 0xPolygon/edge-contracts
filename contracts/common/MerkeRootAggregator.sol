// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MerkleRootAggregator {
    struct MerkeRootNode {
        uint256 merkleRoot;
        uint256[2] aggregatedSignature;
        uint256 validatorSetIndex;
        bytes validatorBitmap;
    }

    MerkeRootNode[] _submittedMerkleRoots;

    function _storeNewMerkleRoot(MerkeRootNode storage newRoot) internal {
        _submittedMerkleRoots.push(newRoot);
    }

    function _getLatestMerkleRoot() internal view returns (MerkeRootNode memory) {
        return _submittedMerkleRoots[_submittedMerkleRoots.length - 1];
    }
}
