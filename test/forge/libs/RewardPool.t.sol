// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {NoTokensDelegated, RewardPoolLib} from "contracts/libs/RewardPool.sol";
import {SafeMathInt, SafeMathUint} from "contracts/libs/SafeMathInt.sol";

import "../utils/TestPlus.sol";

contract RewardPoolTest is Test {
    using RewardPoolLib for RewardPool;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant MAGNITUDE = 1e18;

    RewardPool pool;
    address accountA;
    address accountB;

    function setUp() public {
        pool.validator = makeAddr("validator");
        accountA = makeAddr("accountA");
        accountB = makeAddr("accountB");
    }

    function testDeposit(uint96[2] memory amounts) public {
        pool.deposit(accountA, amounts[0]);
        pool.deposit(accountB, amounts[1]);

        assertEq(pool.balances[accountA], amounts[0], "Balance A");
        assertEq(pool.balances[accountB], amounts[1], "Balance B");
        assertEq(pool.supply, uint256(amounts[0]) + amounts[1], "Supply");
        assertEq(pool.magnifiedRewardCorrections[accountA], 0, "Correction A");
        assertEq(pool.magnifiedRewardCorrections[accountB], 0, "Correction B");
    }

    function testBalanceOf(uint96[2] memory amounts) public {
        pool.deposit(accountA, 1 ether);
        pool.deposit(accountB, 3 ether);

        assertEq(pool.balanceOf(accountA), 1 ether);
        assertEq(pool.balanceOf(accountB), 3 ether);
    }

    function testWithdraw() public {
        pool.deposit(accountA, 1 ether);
        pool.deposit(accountB, 3 ether);
        pool.distributeReward(8);

        pool.withdraw(accountB, 1 ether);

        assertEq(pool.balances[accountB], 2 ether, "Balance");
        assertEq(pool.supply, 3 ether, "Supply");
        assertEq(pool.magnifiedRewardCorrections[accountB], 2 ether, "Correction");
    }

    function testDistributeReward_AmountZero() public {
        vm.record();

        pool.distributeReward(0);

        // did not continue with execution
        (, bytes32[] memory writes) = (vm.accesses(address(this)));
        assertEq(writes.length, 0);
    }

    function testCannotDistributeReward_NoTokensDelegated() public {
        vm.expectRevert(abi.encodeWithSelector(NoTokensDelegated.selector, (pool.validator)));
        pool.distributeReward(1);
    }

    function testDistributeReward(uint96[2] memory amounts, uint96 reward) public {
        vm.assume(amounts[0] > 0);
        vm.assume(amounts[1] > 0);
        vm.assume(reward > 0);
        pool.deposit(accountA, amounts[0]);
        pool.deposit(accountB, amounts[1]);

        pool.distributeReward(reward);

        assertEq(pool.magnifiedRewardPerShare, (reward * MAGNITUDE) / (uint256(amounts[0]) + amounts[1]));
    }

    function testDeposit_More(uint96[2] memory amounts, uint96 reward) public {
        vm.assume(amounts[0] > 0);
        vm.assume(amounts[1] > 0);
        vm.assume(reward > 0);
        pool.deposit(accountA, amounts[0]);
        pool.distributeReward(reward);

        pool.deposit(accountA, amounts[1]);

        assertEq(pool.balances[accountA], uint256(amounts[0]) + amounts[1], "Balance A");
        assertEq(pool.supply, uint256(amounts[0]) + amounts[1], "Supply");
        assertEq(
            pool.magnifiedRewardCorrections[accountA],
            -1 * (pool.magnifiedRewardPerShare * amounts[1]).toInt256Safe(),
            "Correction A"
        );
    }

    function testTotalRewardsEarned() public {
        pool.deposit(accountA, 2 ether);
        pool.deposit(accountB, 1 ether);
        pool.distributeReward(12 ether);

        assertEq(pool.totalRewardsEarned(accountA), 8 ether);
        assertEq(pool.totalRewardsEarned(accountB), 4 ether);

        address accountC = makeAddr("accountC");
        pool.deposit(accountC, 17 ether);
        pool.distributeReward(10 ether);

        assertEq(pool.totalRewardsEarned(accountA), 9 ether);
        assertEq(pool.totalRewardsEarned(accountB), 4.5 ether);
        assertEq(pool.totalRewardsEarned(accountC), 8.5 ether);

        pool.withdraw(accountC, 17 ether);
        pool.distributeReward(2 ether);

        assertEq(pool.totalRewardsEarned(accountA), 10.333333333333333332 ether);
        assertEq(pool.totalRewardsEarned(accountB), 5.166666666666666666 ether);
        assertEq(pool.totalRewardsEarned(accountC), 8.5 ether);

        pool.deposit(accountC, 1 ether);
        pool.distributeReward(4 ether);

        assertEq(pool.totalRewardsEarned(accountA), 12.333333333333333332 ether);
        assertEq(pool.totalRewardsEarned(accountB), 6.166666666666666666 ether);
        assertEq(pool.totalRewardsEarned(accountC), 9.5 ether);
    }

    function testTotalRewardsEarned(uint96[3] memory amounts, uint96[2] memory rewards) public {
        vm.assume(amounts[0] > 0);
        vm.assume(amounts[1] > 0);
        vm.assume(amounts[2] > 0);
        vm.assume(rewards[0] > 0);
        vm.assume(rewards[1] > 0);

        pool.deposit(accountA, amounts[0]);
        pool.deposit(accountB, amounts[1]);
        pool.distributeReward(rewards[0]);

        assertEq(pool.totalRewardsEarned(accountA), (pool.magnifiedRewardPerShare * amounts[0]) / MAGNITUDE);
        assertEq(pool.totalRewardsEarned(accountB), (pool.magnifiedRewardPerShare * amounts[1]) / MAGNITUDE);

        address accountC = makeAddr("accountC");
        pool.deposit(accountC, amounts[2]);
        pool.distributeReward(rewards[1]);

        assertEq(pool.totalRewardsEarned(accountA), (pool.magnifiedRewardPerShare * amounts[0]) / MAGNITUDE);
        assertEq(pool.totalRewardsEarned(accountB), (pool.magnifiedRewardPerShare * amounts[1]) / MAGNITUDE);
        assertEq(
            pool.totalRewardsEarned(accountC),
            (((pool.magnifiedRewardPerShare * amounts[2]).toInt256Safe() + pool.magnifiedRewardCorrections[accountC]))
                .toUint256Safe() / MAGNITUDE
        );
    }

    function testClaimRewards() public {
        pool.deposit(accountA, 1);
        pool.distributeReward(1 ether);

        pool.claimRewards(accountA);

        assertEq(pool.claimedRewards[accountA], 1 ether);

        pool.distributeReward(2 ether);

        pool.claimRewards(accountA);

        assertEq(pool.claimedRewards[accountA], 3 ether);
    }

    function testClaimableRewards() public {
        pool.deposit(accountA, 1);
        pool.distributeReward(1 ether);

        assertEq(pool.claimableRewards(accountA), 1 ether);

        pool.claimRewards(accountA);

        assertEq(pool.claimableRewards(accountA), 0 ether);
    }
}
