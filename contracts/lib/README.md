# Libraries
##### Library contracts

This directory contains all library contracts in use in the contract suite, with the exception of third-party libraries (such as OpenZeppelin's Arrays Upgradeable, used in Child Validator Set) and the merkle verification contract (which is in [common](../common/)). We will give a high-level overview of the contracts, and then focus more on the high-level usage of the contracts dealing with the queues, pools, and validator tree.

There is natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## AccessList

Edge implements protocol-level access lists for allowing (AllowList) or blocking (BlockList) access to various features of a Supernet, configurable by the administrators of the Supernet. Some of the potential applications of these lists require contracts to be able to check inclusion in the lists. The ability to do so is exposed by precompiles, this contract facilitates checking the precompile for membership.

## ChildManagerLib

Library for use in a registry managing Supernets.

## EIP712MetaTransaction

Helper contract for working with EIP712

## EIP712Upgradeable

Implements an upgradeable modification of EIP712, adapted from OpenZeppelin.
## ModExp

Focuses on mathematical operations related to cryptography.

## SafeMathInt

Conversion between `uint256` and `int256`.

## StakeManagerLib

Library for monitoring validator stake.

## WithdrawalQueue

Library to manage withdrawals of funds from unstaking and rewards withdrawals.
