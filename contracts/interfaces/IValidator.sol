// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct RewardPool {
    uint256 supply;
    uint256 magnifiedRewardPerShare;
    address validator;
    mapping(address => int256) magnifiedRewardCorrections;
    mapping(address => uint256) claimedRewards;
    mapping(address => uint256) balances;
}

struct Validator {
    uint256[4] blsKey;
    uint256 stake;
    uint256 totalStake; // self-stake + delegation
    uint256 commission;
    uint256 withdrawableRewards;
    bool active;
}

struct Node {
    address parent;
    address left;
    address right;
    bool red;
    Validator validator;
}

struct ValidatorTree {
    address root;
    uint256 count;
    uint256 totalStake;
    mapping(address => Node) nodes;
    mapping(address => RewardPool) delegationPools;
}
