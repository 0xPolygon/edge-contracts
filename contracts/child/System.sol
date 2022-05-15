// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract System {
    // pre-compiled contracts
    address public constant PRECOMPILED_NATIVE_TRANSFER_CONTRACT =
        0x0000000000000000000000000000000000002020;
    address public constant PRECOMPILED_SIGS_VERIFICATION_CONTRACT =
        0x0000000000000000000000000000000000002030;

    // pre-compiled gas consumption
    uint256 public constant PRECOMPILED_NATIVE_TRANSFER_CONTRACT_GAS = 21000;
    uint256 public constant PRECOMPILED_SIGS_VERIFICATION_CONTRACT_GAS = 21000;

    // genesis contracts
    address public constant NATIVE_TOKEN_CONTRACT =
        0x0000000000000000000000000000000000001010;
}
