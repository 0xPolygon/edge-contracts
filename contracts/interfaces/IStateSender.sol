// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

interface IL2StateSender {
    struct Validator {
        address _address;
        uint256[4] blsKey;
        uint256 votingPower;
    }

    struct SignedMerkleRoot {
        uint256 merkleRoot;
        uint256[2] aggregatedSignature;
        uint256 validatorSetIndex;
        bytes validatorBitmap;
    }

    function getCurrentMerkleRoot() external view returns (bytes memory);

    function submitSignedMerkleRoot(SignedMerkleRoot memory) external;

    function getSignedMerkleRoot() external view returns (SignedMerkleRoot memory);
}
