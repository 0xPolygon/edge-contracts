// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20Predicate} from "contracts/root/RootERC20Predicate.sol";
import {StateSenderHelper} from "./StateSender.t.sol";
import {Initialized} from "./ExitHelper.t.sol";
import "forge-std/console2.sol";

contract RootERC20PredicateTest is StateSenderHelper, Initialized, Test {
    RootERC20Predicate rootERC20Predicate;

    function setUp() public virtual override(Initialized, StateSenderHelper) {
        Initialized.setUp();
        StateSenderHelper.setUp();

        rootERC20Predicate = new RootERC20Predicate();
        address newChildERC20Predicate = makeAddr("newChildERC20Predicate");
        address newChildTokenTemplate = makeAddr("newChildTokenTemplate");
        address nativeTokenRootAddress = makeAddr("newStateSender");
        rootERC20Predicate.initialize(
            address(stateSender),
            address(exitHelper),
            newChildERC20Predicate,
            newChildTokenTemplate,
            nativeTokenRootAddress
        );
    }

    function testDepositToNative() public {
        address alice = makeAddr("alice");
        uint256 startBalance = 100000000000000;
        vm.startPrank(alice);
        vm.deal(alice, startBalance);
        console2.log(address(checkpointManager));
        console2.log(address(exitHelper));

        // rootERC20Predicate.depositNativeTo{value: 1}(alice);
    }
}
