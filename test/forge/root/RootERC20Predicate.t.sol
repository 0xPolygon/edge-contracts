// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20Predicate} from "contracts/root/RootERC20Predicate.sol";
import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {StateSenderHelper} from "./StateSender.t.sol";
import {Initialized} from "./ExitHelper.t.sol";
import {PredicateHelper} from "./PredicateHelper.t.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import "forge-std/console2.sol";

contract RootERC20PredicateTest is PredicateHelper, Test {
    RootERC20Predicate rootERC20Predicate;
    MockERC20 rootNativeToken;
    address charlie;

    function setUp() public virtual override {
        super.setUp();

        rootNativeToken = new MockERC20();

        charlie = makeAddr("charlie");

        rootERC20Predicate = new RootERC20Predicate();
        address newChildERC20Predicate = address(0x1004);
        address newChildTokenTemplate = address(0x1003);
        rootERC20Predicate.initialize(
            address(stateSender),
            address(exitHelper),
            newChildERC20Predicate,
            newChildTokenTemplate,
            address(rootNativeToken)
        );
    }

    function testDeposit() public {
        rootNativeToken.mint(charlie, 100);

        vm.startPrank(charlie);
        rootNativeToken.approve(address(rootERC20Predicate), 1);
        rootERC20Predicate.deposit(rootNativeToken, 1);
        vm.stopPrank();

        assertEq(rootNativeToken.balanceOf(address(rootERC20Predicate)), 1);
        assertEq(rootNativeToken.balanceOf(address(charlie)), 99);
    }

    function testDepositNativeToken() public {
        uint256 startBalance = 100000000000000;
        vm.deal(charlie, startBalance);

        vm.startPrank(charlie);
        rootERC20Predicate.depositNativeTo{value: 1}(charlie);
        vm.stopPrank();
    }
}
