// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {FlowRateWithdrawalQueue} from "contracts/root/flowrate/FlowRateWithdrawalQueue.sol";
import {RootERC20PredicateFlowRate} from "contracts/root/flowrate/RootERC20PredicateFlowRate.sol";
import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {StateSenderHelper} from "../StateSender.t.sol";
import {PredicateHelper} from "../PredicateHelper.t.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";


contract UninitializedRootERC20PredicateFlowRateTest is Test {
    RootERC20PredicateFlowRate rootERC20PredicateFlowRate;
    address constant TOKEN = address(1234);

    function setUp() public virtual {
        rootERC20PredicateFlowRate = new RootERC20PredicateFlowRate();
    }

    function testUninitPaused() public {
        assertFalse(rootERC20PredicateFlowRate.paused(), "Paused");
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
    uint256 constant CAPACITY = 1000000;
    uint256 constant REFILL_RATE = 277; // Refill each hour.
    uint256 constant LARGE = 100000;


    RootERC20PredicateFlowRate rootERC20PredicateFlowRate;
    MockERC20 erc20Token;
    address superAdmin;
    address pauseAdmin;
    address unpauseAdmin;
    address rateAdmin;
    address childERC20Predicate;

    function setUp() public virtual override {
        PredicateHelper.setUp();
        rootERC20PredicateFlowRate = new RootERC20PredicateFlowRate();
        erc20Token = new MockERC20();

        superAdmin = makeAddr("superadmin");
        pauseAdmin = makeAddr("pauseadmin");
        unpauseAdmin = makeAddr("unpauseadmin");
        rateAdmin = makeAddr("rateadmin");

        childERC20Predicate = address(0x1004);
        address newChildTokenTemplate = address(0x1003);

        rootERC20PredicateFlowRate.initialize(
            superAdmin,
            pauseAdmin,
            unpauseAdmin,
            rateAdmin,
            address(stateSender),
            address(exitHelper),
            childERC20Predicate,
            newChildTokenTemplate,
            address(erc20Token)
        );
    }
}


contract ControlRootERC20PredicateFlowRateTest is InitializedRootERC20PredicateFlowRateTest {
    function testPause() public {
        vm.prank(pauseAdmin);
        rootERC20PredicateFlowRate.pause();
        assertTrue(rootERC20PredicateFlowRate.paused());
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
        assertFalse(rootERC20PredicateFlowRate.paused());
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
        assertTrue(rootERC20PredicateFlowRate.withdrawalQueueActivated());
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
        assertFalse(rootERC20PredicateFlowRate.withdrawalQueueActivated());
    }

    function testDeactivateWithdrawalQueueBadAuth() public {
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();
        vm.prank(pauseAdmin);
        vm.expectRevert();
        rootERC20PredicateFlowRate.deactivateWithdrawalQueue();
    }

    function testSetWithdrawalDelay() public {
        uint256 delay = 1000;
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.setWithdrawalDelay(delay);
        assertEq(rootERC20PredicateFlowRate.withdrawalDelay(), delay);
    }

    function testSetWithdrawalDelayBadAuth() public {
        uint256 delay = 1000;
        vm.prank(pauseAdmin);
        vm.expectRevert();
        rootERC20PredicateFlowRate.setWithdrawalDelay(delay);
    }

    function testSetRateControlThreshold() public {
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.setRateControlThreshold(address(erc20Token), CAPACITY, REFILL_RATE, LARGE);
        assertEq(rootERC20PredicateFlowRate.largeTransferThresholds(address(erc20Token)), LARGE);
        uint256 capacity; 
        uint256 refillRate;
        (capacity, , , refillRate) = rootERC20PredicateFlowRate.flowRateBuckets(address(erc20Token));
        assertEq(capacity, CAPACITY, "Capacity");
        assertEq(refillRate, REFILL_RATE, "Refill rate");
    }

    function testSetRateControlThresholdBadAuth() public {
        vm.prank(pauseAdmin);
        vm.expectRevert();
        rootERC20PredicateFlowRate.setRateControlThreshold(address(erc20Token), CAPACITY, REFILL_RATE, LARGE);
    }

    function testGrantRole() public {
        bytes32 role = rootERC20PredicateFlowRate.RATE_CONTROL_ROLE();
        vm.prank(superAdmin);
        rootERC20PredicateFlowRate.grantRole(role, pauseAdmin);
        assertTrue(rootERC20PredicateFlowRate.hasRole(role, pauseAdmin));
    }

    function testGrantRoleBadAuth() public {
        bytes32 role = rootERC20PredicateFlowRate.RATE_CONTROL_ROLE();
        vm.prank(pauseAdmin);
        vm.expectRevert();
        rootERC20PredicateFlowRate.grantRole(role, pauseAdmin);
    }
}




contract OperationalRootERC20PredicateFlowRateTest is InitializedRootERC20PredicateFlowRateTest {
    event ERC20Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address withdrawer,
        address indexed receiver,
        uint256 amount
    );
    event QueuedWithdrawal(
        address indexed token,
        address indexed withdrawer,
        address indexed receiver,
        uint256 amount,
        bool delayWithdrawalLargeAmount,
        bool delayWithdrawalUnknownToken,
        bool withdrawalQueueActivated
    );
    event NoneAvailable();

    address charlie;

    uint256 constant BRIDGED_VALUE = CAPACITY * 100;
    uint256 constant CHARLIE_REMAINDER = 17;
    uint256 constant BANK_OF_CHARLIE_TREASURY = BRIDGED_VALUE + CHARLIE_REMAINDER;

    function setUp() public virtual override {
        super.setUp();

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

    }


    function testWithdrawal() public {
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = 5;

        // Fake a crosschain transfer from the child chain to the root chain.
        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );
        address childERC20Token = rootERC20PredicateFlowRate.rootTokenToChildToken(address(erc20Token));
        //emit log_named_address("Child ERC 20 token", childERC20Token);

        vm.prank(address(exitHelper));
        vm.expectEmit(true, true, true, true, address(rootERC20PredicateFlowRate));
        emit ERC20Withdraw(address(erc20Token), childERC20Token, alice, bob, amount);
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);

        assertEq(erc20Token.balanceOf(address(charlie)), CHARLIE_REMAINDER, "charlie");
        assertEq(erc20Token.balanceOf(address(alice)), 0, "alice");
        assertEq(erc20Token.balanceOf(address(bob)), amount, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE - amount, "rootERC20PredicateFlowRate");
    }

    function testWithdrawalBadData() public {
        configureFlowRate();
        transferTokensToChild();

        // Have an incomplete data structure
        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob
        );
        vm.prank(address(exitHelper));
        vm.expectRevert();
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
    }

    function testWithdrawalUnconfiguredToken() public {
        transferTokensToChild();
        uint256 amount = 5;

        uint256 now1 = 100;
        vm.warp(now1);

        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );
        vm.prank(address(exitHelper));
        vm.expectEmit(true, true, true, true, address(rootERC20PredicateFlowRate));
        emit QueuedWithdrawal(address(erc20Token), alice, bob, amount, false, true, false);
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);

        assertEq(erc20Token.balanceOf(address(charlie)), CHARLIE_REMAINDER, "charlie");
        assertEq(erc20Token.balanceOf(address(alice)), 0, "alice");
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE, "rootERC20PredicateFlowRate");

        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = rootERC20PredicateFlowRate.getPendingWithdrawals(bob);
        assertEq(pending.length, 1, "Pending withdrawal length");
        assertEq(pending[0].withdrawer, address(alice), "Withdrawer");
        assertEq(pending[0].token, address(erc20Token), "Token");
        assertEq(pending[0].amount, amount, "Amount");
        assertEq(pending[0].timestamp, now1, "Timestamp");
    }

    function testWithdrawalLargeWithdrawal() public {
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = LARGE;

        uint256 now1 = 100;
        vm.warp(now1);

        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );
        vm.prank(address(exitHelper));
        vm.expectEmit(true, true, true, true, address(rootERC20PredicateFlowRate));
        emit QueuedWithdrawal(address(erc20Token), alice, bob, amount, true, false, false);
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);

        assertEq(erc20Token.balanceOf(address(charlie)), CHARLIE_REMAINDER, "charlie");
        assertEq(erc20Token.balanceOf(address(alice)), 0, "alice");
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE, "rootERC20PredicateFlowRate");

        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = rootERC20PredicateFlowRate.getPendingWithdrawals(bob);
        assertEq(pending.length, 1, "Pending withdrawal length");
        assertEq(pending[0].withdrawer, address(alice), "Withdrawer");
        assertEq(pending[0].token, address(erc20Token), "Token");
        assertEq(pending[0].amount, amount, "Amount");
        assertEq(pending[0].timestamp, now1, "Timestamp");
    }

    function testHighFlowRate() public {
        vm.warp(100);
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = LARGE - 1;
        uint256 timesBeforeHighFlowRate = CAPACITY / amount;

        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );
        address childERC20Token = rootERC20PredicateFlowRate.rootTokenToChildToken(address(erc20Token));

        for (uint256 i = 0; i < timesBeforeHighFlowRate; i++) {
            vm.prank(address(exitHelper));
            vm.expectEmit(true, true, true, true, address(rootERC20PredicateFlowRate));
            emit ERC20Withdraw(address(erc20Token), childERC20Token, alice, bob, amount);
            rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
            assertFalse(rootERC20PredicateFlowRate.withdrawalQueueActivated(), "queue activated!");
        }
        assertFalse(rootERC20PredicateFlowRate.withdrawalQueueActivated(), "queue activated!");

        vm.prank(address(exitHelper));
        emit QueuedWithdrawal(address(erc20Token), alice, bob, amount, false, false, true);
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
        assertTrue(rootERC20PredicateFlowRate.withdrawalQueueActivated(), "queue not activated!");
    }

    function testFinaliseQueuedWithdrawalEmptyQueue() public {
        configureFlowRate();
        transferTokensToChild();
        vm.expectEmit(false, false, false, false, address(rootERC20PredicateFlowRate));
        emit NoneAvailable();
        rootERC20PredicateFlowRate.finaliseQueuedWithdrawal(address(bob));
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE, "rootERC20PredicateFlowRate");
    }

    function testFinaliseQueuedWithdrawalSingle() public {
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = LARGE - 1;
        uint256 now1 = 100;
        vm.warp(now1);
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();

        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );
        address childERC20Token = rootERC20PredicateFlowRate.rootTokenToChildToken(address(erc20Token));

        vm.prank(address(exitHelper));
        vm.expectEmit(true, true, true, true, address(rootERC20PredicateFlowRate));
        emit QueuedWithdrawal(address(erc20Token), alice, bob, amount, false, false, true);
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");

        now1 += rootERC20PredicateFlowRate.withdrawalDelay();
        vm.warp(now1);

        vm.expectEmit(true, true, true, true, address(rootERC20PredicateFlowRate));
        emit ERC20Withdraw(address(erc20Token), childERC20Token, alice, bob, amount);
        rootERC20PredicateFlowRate.finaliseQueuedWithdrawal(address(bob));
        assertEq(erc20Token.balanceOf(address(bob)), amount, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE - amount, "rootERC20PredicateFlowRate");
    }

    function testFinaliseQueuedWithdrawalMultiple() public {
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = LARGE - 100;
        uint256 now1 = 100;
        uint256 total;
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();

        for (uint256 i = 0; i < 3; i++) {
            now1 += 70;
            vm.warp(now1);
            total += amount + i;
            bytes memory exitData = abi.encode(
                keccak256("WITHDRAW"),
                erc20Token,
                alice,
                bob,
                amount + i
            );

            vm.prank(address(exitHelper));
            rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
        }
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");

        now1 += rootERC20PredicateFlowRate.withdrawalDelay();
        vm.warp(now1);

        rootERC20PredicateFlowRate.finaliseQueuedWithdrawal(address(bob));
        assertEq(erc20Token.balanceOf(address(bob)), total, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE - total, "rootERC20PredicateFlowRate");
    }

    function testFinaliseQueuedWithdrawalNonAvailable() public {
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = LARGE - 1;
        uint256 now1 = 100;
        vm.warp(now1);
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();

        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );
        vm.prank(address(exitHelper));
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");

        rootERC20PredicateFlowRate.finaliseQueuedWithdrawal(address(bob));
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE, "rootERC20PredicateFlowRate");
    }

    function testFinaliseQueuedWithdrawalComplex() public {
        configureFlowRate();
        transferTokensToChild();
        uint256 amount = LARGE - 100;
        uint256 now1 = 100;
        uint256 total;
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.activateWithdrawalQueue();

        for (uint256 i = 0; i < 3; i++) {
            now1 += 70;
            total += amount + i;
            doL2StateReceiveNoEventCheck(amount + i, now1);
        }
        assertEq(erc20Token.balanceOf(address(bob)), 0, "bob");

        now1 += rootERC20PredicateFlowRate.withdrawalDelay();
        vm.warp(now1);
        amount += amount;
        now1 += 100;
        doL2StateReceiveNoEventCheck(amount, now1);

        rootERC20PredicateFlowRate.finaliseQueuedWithdrawal(address(bob));
        assertEq(erc20Token.balanceOf(address(bob)), total, "bob");
        assertEq(erc20Token.balanceOf(address(rootERC20PredicateFlowRate)), BRIDGED_VALUE - total, "rootERC20PredicateFlowRate");

        FlowRateWithdrawalQueue.PendingWithdrawal[] memory pending = rootERC20PredicateFlowRate.getPendingWithdrawals(bob);
        assertEq(pending.length, 1, "Pending withdrawal length");
        assertEq(pending[0].withdrawer, address(alice), "Withdrawer");
        assertEq(pending[0].token, address(erc20Token), "Token");
        assertEq(pending[0].amount, amount, "Amount");
        assertEq(pending[0].timestamp, now1, "Timestamp");
    }



    function configureFlowRate() private {
        vm.prank(rateAdmin);
        rootERC20PredicateFlowRate.setRateControlThreshold(address(erc20Token), CAPACITY, REFILL_RATE, LARGE);
    }


    function transferTokensToChild() private {
        // Crosschain transfer to child chain. This puts funds into the Root ERC 20 Predicate Flow 
        // Rate bridge contract.
        erc20Token.mint(charlie, BANK_OF_CHARLIE_TREASURY);
        vm.startPrank(charlie);
        erc20Token.approve(address(rootERC20PredicateFlowRate), BRIDGED_VALUE);
        rootERC20PredicateFlowRate.deposit(erc20Token, BRIDGED_VALUE);
        vm.stopPrank();
    }

    function doL2StateReceiveNoEventCheck(uint256 amount, uint256 time) private {
        vm.warp(time);
        bytes memory exitData = abi.encode(
            keccak256("WITHDRAW"),
            erc20Token,
            alice,
            bob,
            amount
        );

        vm.prank(address(exitHelper));
        rootERC20PredicateFlowRate.onL2StateReceive(1, childERC20Predicate, exitData);
    }
}
