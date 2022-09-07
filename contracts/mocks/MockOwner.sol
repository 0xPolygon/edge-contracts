// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../common/Owned.sol";

contract MockOwned is Owned {
    function initialize() external initializer {
        __Owned_init();
    }
}
