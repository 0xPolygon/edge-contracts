// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@utils/Test.sol";

import {NoTokensDelegated, RewardPool, RewardPoolLib} from "contracts/libs/RewardPool.sol";
import {SafeMathInt, SafeMathUint} from "contracts/libs/SafeMathInt.sol";

contract RewardPoolTest is Test {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant MAGNITUDE = 1e18;

    address accountA;
    address accountB;

    RewardPoolLibUser rewardPoolLibUser;

    function setUp() public {
        accountA = makeAddr("accountA");
        accountB = makeAddr("accountB");
        rewardPoolLibUser = new RewardPoolLibUser();
    }

    function testDeposit(uint96[2] memory amounts) public {
        rewardPoolLibUser.deposit(accountA, amounts[0]);
        rewardPoolLibUser.deposit(accountB, amounts[1]);

        assertEq(rewardPoolLibUser.balancesGetter(accountA), amounts[0], "Balance A");
        assertEq(rewardPoolLibUser.balancesGetter(accountB), amounts[1], "Balance B");
        assertEq(rewardPoolLibUser.supplyGetter(), uint256(amounts[0]) + amounts[1], "Supply");
        assertEq(rewardPoolLibUser.magnifiedRewardCorrectionsGetter(accountA), 0, "Correction A");
        assertEq(rewardPoolLibUser.magnifiedRewardCorrectionsGetter(accountB), 0, "Correction B");
    }

    function testBalanceOf() public {
        rewardPoolLibUser.deposit(accountA, 1 ether);
        rewardPoolLibUser.deposit(accountB, 3 ether);

        assertEq(rewardPoolLibUser.balanceOf(accountA), 1 ether);
        assertEq(rewardPoolLibUser.balanceOf(accountB), 3 ether);
    }

    function testWithdraw() public {
        rewardPoolLibUser.deposit(accountA, 1 ether);
        rewardPoolLibUser.deposit(accountB, 3 ether);
        rewardPoolLibUser.distributeReward(8);

        rewardPoolLibUser.withdraw(accountB, 1 ether);

        assertEq(rewardPoolLibUser.balancesGetter(accountB), 2 ether, "Balance");
        assertEq(rewardPoolLibUser.supplyGetter(), 3 ether, "Supply");
        assertEq(rewardPoolLibUser.magnifiedRewardCorrectionsGetter(accountB), 2 ether, "Correction");
    }

    function testDistributeReward_AmountZero() public {
        vm.record();

        rewardPoolLibUser.distributeReward(0);

        // did not write to storage
        (, bytes32[] memory writes) = (vm.accesses(address(this)));
        assertEq(writes.length, 0);
    }

    function testCannotDistributeReward_NoTokensDelegated() public {
        vm.expectRevert(abi.encodeWithSelector(NoTokensDelegated.selector, (rewardPoolLibUser.validatorGetter())));
        rewardPoolLibUser.distributeReward(1);
    }

    function testDistributeReward(uint96[2] memory amounts, uint96 reward) public {
        vm.assume(amounts[0] > 0);
        vm.assume(amounts[1] > 0);
        vm.assume(reward > 0);
        rewardPoolLibUser.deposit(accountA, amounts[0]);
        rewardPoolLibUser.deposit(accountB, amounts[1]);

        rewardPoolLibUser.distributeReward(reward);

        assertEq(
            rewardPoolLibUser.magnifiedRewardPerShareGetter(),
            (reward * MAGNITUDE) / (uint256(amounts[0]) + amounts[1])
        );
    }

    function testDeposit_More(uint96[2] memory amounts, uint96 reward) public {
        vm.assume(amounts[0] > 0);
        vm.assume(amounts[1] > 0);
        vm.assume(reward > 0);
        rewardPoolLibUser.deposit(accountA, amounts[0]);
        rewardPoolLibUser.distributeReward(reward);

        rewardPoolLibUser.deposit(accountA, amounts[1]);

        assertEq(rewardPoolLibUser.balancesGetter(accountA), uint256(amounts[0]) + amounts[1], "Balance A");
        assertEq(rewardPoolLibUser.supplyGetter(), uint256(amounts[0]) + amounts[1], "Supply");
        assertEq(
            rewardPoolLibUser.magnifiedRewardCorrectionsGetter(accountA),
            -1 * (rewardPoolLibUser.magnifiedRewardPerShareGetter() * amounts[1]).toInt256Safe(),
            "Correction A"
        );
    }

    function testTotalRewardsEarned() public {
        rewardPoolLibUser.deposit(accountA, 2 ether);
        rewardPoolLibUser.deposit(accountB, 1 ether);
        rewardPoolLibUser.distributeReward(12 ether);

        assertEq(rewardPoolLibUser.totalRewardsEarned(accountA), 8 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountB), 4 ether);

        address accountC = makeAddr("accountC");
        rewardPoolLibUser.deposit(accountC, 17 ether);
        rewardPoolLibUser.distributeReward(10 ether);

        assertEq(rewardPoolLibUser.totalRewardsEarned(accountA), 9 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountB), 4.5 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountC), 8.5 ether);

        rewardPoolLibUser.withdraw(accountC, 17 ether);
        rewardPoolLibUser.distributeReward(2 ether);

        assertEq(rewardPoolLibUser.totalRewardsEarned(accountA), 10.333333333333333332 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountB), 5.166666666666666666 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountC), 8.5 ether);

        rewardPoolLibUser.deposit(accountC, 1 ether);
        rewardPoolLibUser.distributeReward(4 ether);

        assertEq(rewardPoolLibUser.totalRewardsEarned(accountA), 12.333333333333333332 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountB), 6.166666666666666666 ether);
        assertEq(rewardPoolLibUser.totalRewardsEarned(accountC), 9.5 ether);
    }

    function testTotalRewardsEarned(uint96[3] memory amounts, uint96[2] memory rewards) public {
        vm.assume(amounts[0] > 0);
        vm.assume(amounts[1] > 0);
        vm.assume(amounts[2] > 0);
        vm.assume(rewards[0] > 0);
        vm.assume(rewards[1] > 0);

        rewardPoolLibUser.deposit(accountA, amounts[0]);
        rewardPoolLibUser.deposit(accountB, amounts[1]);
        rewardPoolLibUser.distributeReward(rewards[0]);

        assertEq(
            rewardPoolLibUser.totalRewardsEarned(accountA),
            (rewardPoolLibUser.magnifiedRewardPerShareGetter() * amounts[0]) / MAGNITUDE
        );
        assertEq(
            rewardPoolLibUser.totalRewardsEarned(accountB),
            (rewardPoolLibUser.magnifiedRewardPerShareGetter() * amounts[1]) / MAGNITUDE
        );

        address accountC = makeAddr("accountC");
        rewardPoolLibUser.deposit(accountC, amounts[2]);
        rewardPoolLibUser.distributeReward(rewards[1]);

        assertEq(
            rewardPoolLibUser.totalRewardsEarned(accountA),
            (rewardPoolLibUser.magnifiedRewardPerShareGetter() * amounts[0]) / MAGNITUDE
        );
        assertEq(
            rewardPoolLibUser.totalRewardsEarned(accountB),
            (rewardPoolLibUser.magnifiedRewardPerShareGetter() * amounts[1]) / MAGNITUDE
        );
        assertEq(
            rewardPoolLibUser.totalRewardsEarned(accountC),
            (
                ((rewardPoolLibUser.magnifiedRewardPerShareGetter() * amounts[2]).toInt256Safe() +
                    rewardPoolLibUser.magnifiedRewardCorrectionsGetter(accountC))
            ).toUint256Safe() / MAGNITUDE
        );
    }

    function testClaimRewards() public {
        rewardPoolLibUser.deposit(accountA, 1);
        rewardPoolLibUser.distributeReward(1 ether);

        rewardPoolLibUser.claimRewards(accountA);

        assertEq(rewardPoolLibUser.claimedRewardsGetter(accountA), 1 ether);

        rewardPoolLibUser.distributeReward(2 ether);

        rewardPoolLibUser.claimRewards(accountA);

        assertEq(rewardPoolLibUser.claimedRewardsGetter(accountA), 3 ether);
    }

    function testClaimableRewards() public {
        rewardPoolLibUser.deposit(accountA, 1);
        rewardPoolLibUser.distributeReward(1 ether);

        assertEq(rewardPoolLibUser.claimableRewards(accountA), 1 ether);

        rewardPoolLibUser.claimRewards(accountA);

        assertEq(rewardPoolLibUser.claimableRewards(accountA), 0 ether);

        rewardPoolLibUser.distributeReward(3 ether);

        assertEq(rewardPoolLibUser.claimableRewards(accountA), 3 ether);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract RewardPoolLibUser {
    RewardPool pool;

    constructor() {
        pool.validator = address(this);
    }

    function distributeReward(uint256 amount) external {
        RewardPoolLib.distributeReward(pool, amount);
    }

    function deposit(address account, uint256 amount) external {
        RewardPoolLib.deposit(pool, account, amount);
    }

    function withdraw(address account, uint256 amount) external {
        RewardPoolLib.withdraw(pool, account, amount);
    }

    function claimRewards(address account) external returns (uint256) {
        uint256 r = RewardPoolLib.claimRewards(pool, account);
        return r;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 r = RewardPoolLib.balanceOf(pool, account);
        return r;
    }

    function totalRewardsEarned(address account) external view returns (uint256) {
        uint256 r = RewardPoolLib.totalRewardsEarned(pool, account);
        return r;
    }

    function claimableRewards(address account) external view returns (uint256) {
        uint256 r = RewardPoolLib.claimableRewards(pool, account);
        return r;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        GETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function supplyGetter() external view returns (uint256) {
        return pool.supply;
    }

    function magnifiedRewardPerShareGetter() external view returns (uint256) {
        return pool.magnifiedRewardPerShare;
    }

    function validatorGetter() external view returns (address) {
        return pool.validator;
    }

    function magnifiedRewardCorrectionsGetter(address a) external view returns (int256) {
        return pool.magnifiedRewardCorrections[a];
    }

    function claimedRewardsGetter(address a) external view returns (uint256) {
        return pool.claimedRewards[a];
    }

    function balancesGetter(address a) external view returns (uint256) {
        return pool.balances[a];
    }
}
