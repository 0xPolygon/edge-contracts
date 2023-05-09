// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/root/staking/IStakeManager.sol";

struct Stakes {
    uint256 totalStake;
    // validator => child => amount
    mapping(address => mapping(uint256 => uint256)) stakes;
    // child chain => total stake
    mapping(uint256 => uint256) totalStakePerChild;
    mapping(address => uint256) totalStakes;
    mapping(address => uint256) withdrawableStakes;
}

library StakeManagerLib {
    function addStake(Stakes storage self, address validator, uint256 id, uint256 amount) internal {
        self.stakes[validator][id] += amount;
        self.totalStakePerChild[id] += amount;
        self.totalStakes[validator] += amount;
        self.totalStake += amount;
    }

    function removeStake(Stakes storage self, address validator, uint256 id, uint256 amount) internal {
        self.stakes[validator][id] -= amount;
        self.totalStakePerChild[id] -= amount;
        self.totalStakes[validator] -= amount;
        self.totalStake -= amount;
        self.withdrawableStakes[validator] += amount;
    }

    function withdrawStake(Stakes storage self, address validator, uint256 amount) internal {
        self.withdrawableStakes[validator] -= amount;
    }

    function withdrawableStakeOf(Stakes storage self, address validator) internal view returns (uint256 amount) {
        amount = self.withdrawableStakes[validator];
    }

    function totalStakeOfChild(Stakes storage self, uint256 id) internal view returns (uint256 amount) {
        amount = self.totalStakePerChild[id];
    }

    function stakeOf(Stakes storage self, address validator, uint256 id) internal view returns (uint256 amount) {
        amount = self.stakes[validator][id];
    }

    function totalStakeOf(Stakes storage self, address validator) internal view returns (uint256 amount) {
        amount = self.totalStakes[validator];
    }
}
