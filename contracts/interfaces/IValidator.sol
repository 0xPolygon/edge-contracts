// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Validator {
    uint256[4] blsKey;
    uint256 stake;
    uint256 totalStake; // self-stake + delegation
    uint256 commission;
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
}
