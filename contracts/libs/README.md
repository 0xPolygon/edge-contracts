# Libraries

##### Library contracts

This directory contains all library contracts in use in the contract suite, with the exception of third-party libraries (such as OpenZeppelin's Arrays Upgradeable, used in Child Validator Set) and the merkle verification contract (which is in [common](../common/)). We will give a high-level overview of the contracts, and then focus more on the high-level usage of the contracts dealing with the queues, pools, and validator tree.

There is natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## `ModExp.sol`

Focuses on mathematical operations related to cryptography.

## `SafeMathInt.sol`

Conversion between `uint256` and `int256`.

## `RewardPool.sol`

Library for the management of reward pools. Each validator has a reward pool for delegators delegating funds to them. This will be explained further below.

## ValidatorQueue.sol

Library for processing new (post-genesis) validators and changes to existing validators. These changes only become canonical at the end of the epoch they were submitted, the queue holds them and is cleared every epoch. Explained in further detail below.

## ValidatorStorage

Red-black ordered statistic tree for ordering validators by total stake. (Total stake is the amount of stake the validator has staked from their own address, in addition to any funds delegated to them.) Explained in further detail below.

(Further links on red-black trees are included in comments in the contract.)

## WithdrawalQueue.sol

Library to manage withdrawals of funds from unstaking, undelegating, and rewards withdrawals. Each address has its own queue, the queue manages various system-enforced delays to withdrawals. Explained in further detail below.

## Queue, Pool, and Tree libs in More Detail

These libraries were written to help facilitate gas-efficient management of the validator set and rewards distribution. These operations are done through the [Child Validator Set](../child/ChildValidatorSet.sol) contract, which imports and makes use of these libraries.

We'll start with a brief walk through registering a new validator in order to illustrate where each library plays a role. Anytime after genesis, new validators enter the system through the `register()` function in Child Validator Set. (Note that this implementation of Child Validator set has a whitelist, so a potential validator must be whitelisted before being able to register.)

Registration will put the validator into the Validator Queue. This queue is used anytime a new validator is registered or anytime there is a change to the data of a validator, such as depositing additional stake or withdrawing from it, or receiving new delegations or delegators removing them. These changes only become canonical at the end of the epoch that they are received. The queue serves to hold all of these pending changes, which are then implemented at the end of the epoch. The queue must be cleared (reset) in order for the next epoch to begin, so each epoch begins with a fresh queue.

The new validator is placed in the tree described in `ValidatorStorage.sol`. Since at current the active validator set is determined by highest stake, the tree allows the system to order all validators by total stake (self-stake + delegations) efficiently even as staked amounts fluctuate and validators are added and/or removed.

Each validator has a Reward Pool. The rewards that a validator receives are split between the validator and the delegators of that validator. The pool holds the delegators' share of the rewards, and maintains an accounting system for determining the delegators' shares in the pool. Rewards, whether to a validator (from stake) or to a delegator, do not autocompound, as to say that if a validator has a stake of 10 and earns 1 in rewards, their stake remains 10, and they have a separate one in rewards.

Unstaking, undelegating, and rewards withdrawal have delays associated with them. The Withdrawal Queue library exists to manage withdrawls. Each address has their own separate queue to manage their individual withdrawals.
