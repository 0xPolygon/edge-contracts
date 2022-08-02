// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Validator {
    address parent;
    address left;
    address right;
    bool red;
    uint256 stake;
    uint256 totalStake; // self-stake + delegation
    uint256 commission;
}

struct ValidatorTree {
    address root;
    uint256 count;
    mapping(address => Validator) nodes;
}
