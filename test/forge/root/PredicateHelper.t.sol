// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20Predicate} from "contracts/root/RootERC20Predicate.sol";
import {StateSenderHelper} from "./StateSender.t.sol";
import {Initialized} from "./ExitHelper.t.sol";
import "forge-std/console2.sol";

// An abstract contract that can be used for the setup of all predicates
abstract contract PredicateHelper is StateSenderHelper, Initialized {
    function setUp() public virtual override(Initialized, StateSenderHelper) {
        Initialized.setUp();
        StateSenderHelper.setUp();
    }
}
