// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IValidator.sol";
import "./SafeMathInt.sol";

error NoTokensDelegated(address validator);

library RewardPoolLib {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    function distributeReward(RewardPool storage pool, uint256 amount) internal {
        if (amount == 0) return;
        if (pool.supply == 0) revert NoTokensDelegated(pool.validator);
        pool.magnifiedRewardPerShare += (amount * magnitude()) / pool.supply;
    }

    function deposit(
        RewardPool storage pool,
        address account,
        uint256 amount
    ) internal {
        pool.balances[account] += amount;
        pool.supply += amount;
        pool.magnifiedRewardCorrections[account] -= (pool.magnifiedRewardPerShare * amount).toInt256Safe();
    }

    function withdraw(
        RewardPool storage pool,
        address account,
        uint256 amount
    ) internal {
        pool.balances[account] -= amount;
        pool.supply -= amount;
        pool.magnifiedRewardCorrections[account] += (pool.magnifiedRewardPerShare * amount).toInt256Safe();
    }

    function claimRewards(RewardPool storage pool, address account) internal returns (uint256 reward) {
        reward = claimableRewards(pool, account);
        pool.claimedRewards[account] += reward;
    }

    function balanceOf(RewardPool storage pool, address account) internal view returns (uint256) {
        return pool.balances[account];
    }

    function totalRewardsEarned(RewardPool storage pool, address account) internal view returns (uint256) {
        int256 magnifiedRewards = (pool.magnifiedRewardPerShare * pool.balances[account]).toInt256Safe();
        uint256 correctedRewards = (magnifiedRewards + pool.magnifiedRewardCorrections[account]).toUint256Safe();
        return correctedRewards / magnitude();
    }

    function claimableRewards(RewardPool storage pool, address account) internal view returns (uint256) {
        return totalRewardsEarned(pool, account) - pool.claimedRewards[account];
    }

    function magnitude() private pure returns (uint256) {
        return 1e18;
    }
}
