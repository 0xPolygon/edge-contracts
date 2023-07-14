// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStateSender {
    // TODO: Move Validator struct from CheckpointManager to common lib
    struct Validator {
        address _address;
        uint256[4] blsKey;
        uint256 votingPower;
    }
    
    function syncState(address receiver, bytes calldata data) external;
}
