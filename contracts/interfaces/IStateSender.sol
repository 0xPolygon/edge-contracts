// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStateSender {
    struct Validator {
        uint256[4] pubkey;
    }
    
    function syncState(address receiver, bytes calldata data) external;
}
