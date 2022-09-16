// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IValidator.sol";
import "./SafeMathInt.sol";

error NoTokensDelegated(address validator);

/**
 * @title Reward Pool Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice library for distributing rewards
 * @dev structs can be found in the IValidator interface
 */
library RewardPoolLib {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    /**
     * @notice distributes an amount to a pool
     * @param pool the RewardPool for rewards to be distributed to
     * @param amount the total amount to be distributed
     */
    function distributeReward(RewardPool storage pool, uint256 amount) internal {
        if (amount == 0) return;
        if (pool.supply == 0) revert NoTokensDelegated(pool.validator);
        pool.magnifiedRewardPerShare += (amount * magnitude()) / pool.supply;
    }

    /**
     * @notice credits the balance of a specific pool member
     * @param pool the RewardPool of the account to credit
     * @param account the address to be credited
     * @param amount the amount to credit the account by
     */
    function deposit(
        RewardPool storage pool,
        address account,
        uint256 amount
    ) internal {
        pool.balances[account] += amount;
        pool.supply += amount;
        pool.magnifiedRewardCorrections[account] -= (pool.magnifiedRewardPerShare * amount).toInt256Safe();
    }

    /**
     * @notice decrements the balance of a specific pool member
     * @param pool the RewardPool of the account to decrement the balance of
     * @param account the address to decrement the balance of
     * @param amount the amount to decrement the balance by
     */
    function withdraw(
        RewardPool storage pool,
        address account,
        uint256 amount
    ) internal {
        pool.balances[account] -= amount;
        pool.supply -= amount;
        pool.magnifiedRewardCorrections[account] += (pool.magnifiedRewardPerShare * amount).toInt256Safe();
    }

    /**
     * @notice increments the amount rewards claimed by an account
     * @param pool the RewardPool the rewards have been claimed from
     * @param account the address claiming the rewards
     * @return reward the amount of rewards claimed
     */
    function claimRewards(RewardPool storage pool, address account) internal returns (uint256 reward) {
        reward = claimableRewards(pool, account);
        pool.claimedRewards[account] += reward;
    }

    /**
     * @notice returns the balance of an account in a specific pool
     * @param pool the RewardPool to query the balance from
     * @param account the address to query the balance of
     * @return uint256 the balance of the account
     */
    function balanceOf(RewardPool storage pool, address account) internal view returns (uint256) {
        return pool.balances[account];
    }

    /**
     * @notice returns the historical total rewards earned by an account in a specific pool
     * @param pool the RewardPool to query the total from
     * @param account the address to query the balance of
     * @return uint256 the total claimed by the account
     */
    function totalRewardsEarned(RewardPool storage pool, address account) internal view returns (uint256) {
        int256 magnifiedRewards = (pool.magnifiedRewardPerShare * pool.balances[account]).toInt256Safe();
        uint256 correctedRewards = (magnifiedRewards + pool.magnifiedRewardCorrections[account]).toUint256Safe();
        return correctedRewards / magnitude();
    }

    /**
     * @notice returns the current amount of claimable rewards for an address in a pool
     * @param pool the RewardPool to query the claimable rewards from
     * @param account the address for which query the amount of claimable rewards
     * @return uint256 the amount of claimable rewards for the address
     */
    function claimableRewards(RewardPool storage pool, address account) internal view returns (uint256) {
        return totalRewardsEarned(pool, account) - pool.claimedRewards[account];
    }

    /**
     * @notice returns the scaling factor used for decimal places
     * @dev this means the last 18 places in a number are to the right of the decimal point
     * @return uint256 the scaling factor
     */
    function magnitude() private pure returns (uint256) {
        return 1e18;
    }
}
