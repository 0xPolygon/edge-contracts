// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IValidator
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @dev even though the natspec on the structs is not output,
 *  it is included for clarity
 */

/**
 * @notice struct representation of a pool for reward distribution
 * @dev pools are formed by delegators to a specific validator
 * @dev uses virtual balances to track slashed delegations
 * @param supply amount of tokens in the pool
 * @param virtualSupply the total supply of virtual balances in the pool
 * @param magnifiedRewardPerShare coefficient to aggregate rewards
 * @param validator the address of the validator the pool based on
 * @param magnifiedRewardCorrections adjustments to reward magnifications by address
 * @param claimedRewards amount claimed by address
 * @param balances virtual balance by address
 */
struct RewardPool {
    uint256 supply;
    uint256 virtualSupply;
    uint256 magnifiedRewardPerShare;
    address validator;
    mapping(address => int256) magnifiedRewardCorrections;
    mapping(address => uint256) claimedRewards;
    mapping(address => uint256) balances;
}

/**
 * @notice data type representing a validator
 * @param blsKey the public BLS key of the validator
 * @param stake amount staked by the validator
 * @param commission fee taken from delegators' rewards and given to the validator
 * @param withdrawableRewards amount that can be withdrawn from
 * @param active if this validator is actively proposing/attesting
 */
struct Validator {
    uint256[4] blsKey;
    uint256 stake;
    uint256 commission;
    uint256 withdrawableRewards;
    bool active;
}

/**
 * @notice data type for nodes in the red-black validator tree
 * @param parent address of the parent of this node
 * @param left the node in the tree to the left of this one
 * @param right the node in the tree to the right of this one
 * @param red bool denoting color of node for balancing
 */
struct Node {
    address parent;
    address left;
    address right;
    bool red;
    Validator validator;
}

/**
 * @notice data type for the red-black validator tree
 * @param root
 * @param count amount of nodes in the tree
 * @param totalStake total amount staked by nodes of the tree
 * @param nodes address to node mapping
 * @param delegationPools validator RewardPools by validator address
 */
struct ValidatorTree {
    address root;
    uint256 count;
    uint256 totalStake;
    mapping(address => Node) nodes;
    mapping(address => RewardPool) delegationPools;
}
