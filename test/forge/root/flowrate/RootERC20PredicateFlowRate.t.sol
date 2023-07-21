// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20PredicateFlowRate} from "contracts/root/flowrate/RootERC20PredicateFlowRate.sol";
import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {StateSenderHelper} from "../StateSender.t.sol";
import {Initialized} from "../ExitHelper.t.sol";
import {PredicateHelper} from "../PredicateHelper.t.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";


contract UninitializedRootERC20PredicateFlowRateTest is PredicateHelper, Test {
    RootERC20PredicateFlowRate rootERC20PredicateFlowRate;
    MockERC20 erc20Token;
    address charlie;

    function setUp() public virtual override {
        super.setUp();

        erc20Token = new MockERC20();

        charlie = makeAddr("charlie");

        rootERC20PredicateFlowRate = new RootERC20PredicateFlowRate();
        address newChildERC20Predicate = address(0x1004);
        address newChildTokenTemplate = address(0x1003);
        rootERC20PredicateFlowRate.initialize(
            address(stateSender),
            address(exitHelper),
            newChildERC20Predicate,
            newChildTokenTemplate,
            address(erc20Token)
        );
    }
}


contract RootERC20PredicateFlowRateTest is PredicateHelper, Test {
    RootERC20PredicateFlowRate rootERC20PredicateFlowRate;
    MockERC20 rootNativeToken;
    address charlie;

    function setUp() public virtual override {
        super.setUp();

        rootNativeToken = new MockERC20();

        charlie = makeAddr("charlie");

        rootERC20PredicateFlowRate = new RootERC20PredicateFlowRate();
        address newChildERC20Predicate = address(0x1004);
        address newChildTokenTemplate = address(0x1003);
        rootERC20PredicateFlowRate.initialize(
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
        rootNativeToken.approve(address(rootERC20PredicateFlowRate), 1);
        rootERC20PredicateFlowRate.deposit(rootNativeToken, 1);
        vm.stopPrank();

        assertEq(rootNativeToken.balanceOf(address(rootERC20PredicateFlowRate)), 1);
        assertEq(rootNativeToken.balanceOf(address(charlie)), 99);
    }


}
