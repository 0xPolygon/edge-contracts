// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/interfaces/IValidator.sol";

abstract contract TestPlus is Test {
    function assertNotEq(uint256 a, uint256 b) internal virtual {
        if (a == b) {
            emit log("Error: a != b not satisfied [uint]");
            emit log_named_uint("Not expected", b);
            emit log_named_uint("      Actual", a);
            fail();
        }
    }

    function assertEq(Validator memory a, Validator memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [Validator]");
            fail();
        }
    }

    function assertEq(
        Validator memory a,
        Validator memory b,
        string memory err
    ) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            emit log("Error: a == b not satisfied [Validator]");
            fail();
        }
    }
}
