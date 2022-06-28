// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Initializable {
    uint8 private _initialized;

    modifier initializer() {
        require(_initialized == 0, "ALREADY_INITIALIZED");

        _;

        _initialized = 1;
    }
}
