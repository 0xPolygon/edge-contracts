// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// 💬 ABOUT
// StdAssertions and custom assertions.

// 🧩 MODULES
import {StdAssertions} from "forge-std/StdAssertions.sol";

// 📦 BOILERPLATE
import {StateReceiver} from "contracts/child/StateReceiver.sol";
import {Withdrawal} from "contracts/lib/WithdrawalQueue.sol";
import {RewardPool, Validator, Node, ValidatorTree} from "contracts/interfaces/lib/IValidator.sol";

// ⭐️ ASSERTIONS
abstract contract Assertions is StdAssertions {
    function assertNotEq(uint256 a, uint256 b) internal virtual {
        if (a == b) {
            emit log("Error: a != b not satisfied [uint]");
            emit log_named_uint("Not expected", b);
            emit log_named_uint("      Actual", a);
            fail();
        }
    }

    function assertEq(Validator memory a, Validator memory b) internal virtual {
        _compareHash(keccak256(abi.encode(a)), keccak256(abi.encode(b)), "Validator");
    }

    function assertEq(Validator memory a, Validator memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(Node memory a, Node memory b) internal virtual {
        _compareHash(keccak256(abi.encode(a)), keccak256(abi.encode(b)), "Node");
    }

    function assertEq(Withdrawal memory a, Withdrawal memory b) internal virtual {
        _compareHash(keccak256(abi.encode(a)), keccak256(abi.encode(b)), "Withdrawal");
    }

    function assertEq(
        StateReceiver.StateSyncCommitment memory a,
        StateReceiver.StateSyncCommitment memory b
    ) internal virtual {
        _compareHash(keccak256(abi.encode(a)), keccak256(abi.encode(b)), "StateSyncCommitment");
    }

    function _compareHash(bytes32 a, bytes32 b, string memory typeName) private {
        if (a != b) {
            emit log(string.concat("Error: a == b not satisfied [", typeName, "]"));
            fail();
        }
    }
}
