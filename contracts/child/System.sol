// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/Errors.sol";

contract System {
    // pre-compiled contracts
    // slither-disable-next-line too-many-digits
    address public constant NATIVE_TRANSFER_PRECOMPILE = 0x0000000000000000000000000000000000002020;
    // slither-disable-next-line too-many-digits
    address public constant VALIDATOR_PKCHECK_PRECOMPILE = 0x0000000000000000000000000000000000002030;

    // internal addrs
    // slither-disable-next-line too-many-digits
    address public constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    // pre-compiled gas consumption
    // slither-disable-next-line too-many-digits
    uint256 public constant NATIVE_TRANSFER_PRECOMPILE_GAS = 21000;
    // slither-disable-next-line too-many-digits
    uint256 public constant VALIDATOR_PKCHECK_PRECOMPILE_GAS = 150000;

    // genesis contracts
    // slither-disable-next-line too-many-digits
    address public constant NATIVE_TOKEN_CONTRACT = 0x0000000000000000000000000000000000001010;

    modifier onlySystemCall() {
        if (msg.sender != SYSTEM) revert Unauthorized("SYSTEMCALL");
        _;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
