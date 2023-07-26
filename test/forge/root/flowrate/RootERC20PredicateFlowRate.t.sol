// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20PredicateFlowRate} from "contracts/root/flowrate/RootERC20PredicateFlowRate.sol";
import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {StateSenderHelper} from "../StateSender.t.sol";
import {Initialized} from "../ExitHelper.t.sol";
import {PredicateHelper} from "../PredicateHelper.t.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";


contract UninitializedRootERC20PredicateFlowRateTest is Test {
    RootERC20PredicateFlowRate rootERC20PredicateFlowRate;
    address constant TOKEN = address(1234);

    function setUp() public virtual {
        rootERC20PredicateFlowRate = new RootERC20PredicateFlowRate();
    }

    function testUninitPaused() public {
        assertEq(rootERC20PredicateFlowRate.paused(), false, "Paused");
    }

    function testUninitLargeTransferThresholds() public {
        assertEq(rootERC20PredicateFlowRate.largeTransferThresholds(TOKEN), 0, "largeTransferThresholds");
    }

    function testWrongInit() public {
        vm.expectRevert();
        rootERC20PredicateFlowRate.initialize(address(0), address(0), address(0), address(0), address(0));
    }
}

contract InitializedRootERC20PredicateFlowRateTest is PredicateHelper {
    RootERC20PredicateFlowRate rootERC20PredicateFlowRate;
    MockERC20 erc20Token;
    address superAdmin;
    address pauseAdmin;
    address unpauseAdmin;
    address rateAdmin;

    function setUp() public virtual override {
        PredicateHelper.setUp();
        rootERC20PredicateFlowRate = new RootERC20PredicateFlowRate();
        erc20Token = new MockERC20();

        superAdmin = makeAddr("superadmin");
        pauseAdmin = makeAddr("pauseadmin");
        unpauseAdmin = makeAddr("unpauseadmin");
        rateAdmin = makeAddr("rateadmin");

        address newChildERC20Predicate = address(0x1004);
        address newChildTokenTemplate = address(0x1003);

        rootERC20PredicateFlowRate.initialize(
            superAdmin,
            pauseAdmin,
            unpauseAdmin,
            rateAdmin,
            address(stateSender),
            address(exitHelper),
            newChildERC20Predicate,
            newChildTokenTemplate,
            address(erc20Token)
        );
    }
}


contract ControlRootERC20PredicateFlowRateTest is InitializedRootERC20PredicateFlowRateTest {
    function testPause() public {
        vm.prank(pauseAdmin);
        rootERC20PredicateFlowRate.pause();
        assertEq(rootERC20PredicateFlowRate.paused(), true);
    }

    function testPauseBadAuth() public {
        vm.expectRevert();
        vm.prank(unpauseAdmin);
        rootERC20PredicateFlowRate.pause();
    }

    function testUnpause() public {
        vm.prank(pauseAdmin);
        rootERC20PredicateFlowRate.pause();
        vm.prank(unpauseAdmin);
        rootERC20PredicateFlowRate.unpause();
        assertEq(rootERC20PredicateFlowRate.paused(), false);
    }

    function testUnpauseBadAuth() public {
        vm.prank(pauseAdmin);
        rootERC20PredicateFlowRate.pause();
        vm.expectRevert();
        rootERC20PredicateFlowRate.unpause();
    }

    function testActivateWithdrawalQueue() public {
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();
        assertEq(rootERC20PredicateFlowRate.withdrawalQueueActivated(), true);
    }

    function testActivateWithdrawalQueueBadAuth() public {
        vm.prank(pauseAdmin);
        vm.expectRevert();
        rootERC20PredicateFlowRate.activateWithdrawalQueue();
    }

    function testDeactivateWithdrawalQueue() public {
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.deactivateWithdrawalQueue();
        assertEq(rootERC20PredicateFlowRate.withdrawalQueueActivated(), false);
    }

    function testDeactivateWithdrawalQueueBadAuth() public {
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();
        vm.prank(pauseAdmin);
        vm.expectRevert();
        rootERC20PredicateFlowRate.deactivateWithdrawalQueue();
    }
}




contract RootERC20PredicateFlowRateTest is InitializedRootERC20PredicateFlowRateTest {
    address charlie;

    function setUp() public virtual override {
        super.setUp();

        charlie = makeAddr("charlie");

    }

    function testDeposit() public {
       erc20Token.mint(charlie, 100);

        vm.startPrank(charlie);
        erc20Token.approve(address(rootERC20PredicateFlowRate), 1);
        rootERC20PredicateFlowRate.deposit(erc20Token, 1);
        vm.stopPrank();

        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), 1);
        assertEq(erc20Token.balanceOf(address(charlie)), 99);
    }


}
