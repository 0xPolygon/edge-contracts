// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// 💬 ABOUT
// Custom Test.

// 🧩 MODULES
//import {console} from "forge-std/console.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Assertions} from "./Assertions.sol";
//import {StdChains} from "forge-std/StdChains.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {stdError} from "forge-std/StdError.sol";
//import {stdJson} from "forge-std/StdJson.sol";
//import {stdMath} from "forge-std/StdMath.sol";
//import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
//import {Vm} from "forge-std/Vm.sol";

// 📦 BOILERPLATE
import {TestBase} from "forge-std/Base.sol";
import {DSTest} from "ds-test/test.sol";

// ⭐️ TEST
abstract contract Test is DSTest, Assertions, StdCheats, StdUtils, TestBase {

}
