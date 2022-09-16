# Child

##### Contracts providing functionality on the child chain

This directory contains contracts meant for usage on the child chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## State Receiver

This contract represents the child side of the message bridge.

Data from the root chain (sent via [`StateSender.sol`](../root/StateSender.sol)) is indexed and then signed by validators, and a merkle tree of such data is then submitted to the child chain through the `commit()` function in this contract. Once the merkle tree has been committed, anyone can call the `execute()` function in State Receiver. This means that even though validators will call `execute()` periodically, a user wishing to expedite execution may call it themselves, provided they possess the payload and merkle proof.

## Child Validator Set

This contract is the central contract for everything related to validators and validation. It contains the functions for registering a validator, for staking and unstaking, delegating funds to a validator and undelegating those funds, validator selection, reward distribution and withdrawal, and validator removal. It also serves as the hub for committing epochs as a validator and epoch.

In the current implementation potential validators must be whitelisted before being able to register. Child Validator Set also includes the functionality related to the whitelist.

Lastly, a validator by default splits protocol rewards with the validator's delegators. The validator possesses the ability to further incentivize delegators by committing some of the validator's own portion of rewards to the delegators. This functionality is also located in Child Validator Set, in the `setCommission()` function.

There are a number of libraries to assist in these processes which are described in greater detail in [`libs/`](../libs/README.md).

## MRC

This contract serves as a wrapper to the child chain's native asset in order to treat it like an ERC20 asset. This helps facilitate bridging. The contract also can receive StateSync events to reflect balance changes from bridging. One additional point worth mentioning is that transfers are done using a precompile, making them less gas-intensive.

## System

A contract template adding various child-specific addresses, for example, to determine if a call is sent from a client (validator) as a protocol-specific tx (such as bridging data). Precompile addresses are also defined here.

## Future

A contract is likely to be added later to further facilitate sending events to root (communicating specifically with `CheckpointManager.sol`).
