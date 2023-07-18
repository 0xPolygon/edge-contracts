// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20Predicate} from "contracts/root/RootERC20Predicate.sol";

contract RootERC20PredicateTest is Test {
    RootERC20Predicate rootERC20Predicate;

    function setUp() public {
        rootERC20Predicate = new RootERC20Predicate();
        address newStateSender = makeAddr("newStateSender");
        address newExitHelper = makeAddr("newExitHelper");
        address newChildERC20Predicate = makeAddr("newChildERC20Predicate");
        address newChildTokenTemplate = makeAddr("newChildTokenTemplate");
        address nativeTokenRootAddress = makeAddr("newStateSender");
        rootERC20Predicate.initialize(
            newStateSender,
            newExitHelper,
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

        rootERC20Predicate.depositNativeTo{value: 1}(alice);
    }
}
