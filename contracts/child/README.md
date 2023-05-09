# Child

##### Contracts providing functionality on the child chain

This directory contains contracts meant for usage on the child chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## Token Contracts

The `ChildERC20`, `ChildERC721`, `ChildERC1155`, `NativeERC20`, and `NativeERC20Mintable` contracts represent templates for the management of bridged assets on the child chain. The latter two represent assets which are an ERC20 on the root chain, but used as the native asset (for the payment of gas) on the child chain. The `NativeERC20Mintable` allows for more of the asset to be minted on the child chain directly. The other contracts assume the supply is dictated by the root asset, and cannot mint more of the asset directly. Work is already underway to add Mintable templates for ERC20/721/1155 tokens.

The predicate contracts provide an interface for the bridge to manage transactions involving assets of their respective standards. These are provided in two forms, a regular template and access list version. Supernets can be made permissioned, and the access list versions of the predicate check to see if the address interacting with the bridge has the permissions to do so using either a inclusionary list (AllowList) or exclusionary list (BlockList). Usage of these lists can be turned off at any time by the Supernet's administrators.

## EIP1559Burn

For use in Supernets that wish to have a mechanism similar to EIP1559, burning a portion of the assets used to pay gas fees - the fees are sent to this contract, then withdrawn to root to be burnt.

## ForkParams

Allows for the inclusion of softfork features on the child chain. Read by the client each epoch.

## L2StateSender

A simple arbitrary message bridge for sending messages from child to root.

## NetworkParams

Configurable network parameters (such as validator set size and block gas limit) that are read by the client each epoch.

## State Receiver

This contract represents the child side of the message bridge.

Data from the root chain (sent via [`StateSender.sol`](../root/StateSender.sol)) is indexed and then signed by validators, and a merkle tree of such data is then submitted to the child chain through the `commit()` function in this contract. Once the merkle tree has been committed, anyone can call the `execute()` function in State Receiver. This means that even though validators will call `execute()` periodically, a user wishing to expedite execution may call it themselves, provided they possess the payload and merkle proof.

## System

A contract template adding various child-specific addresses, for example, to determine if a call is sent from a client (validator) as a protocol-specific tx (such as bridging data). Precompile addresses are also defined here.

## Child Validator Set

Previous versions of this contract suite included extensive work for the management of the child validator set completely through smart contracts. Much of this work has been lifted directly into the client, removing the need for these contracts.

## `validator/`

There is an additional subdirectory with contracts directly relating to block validation, a separate README in that directory describes the contracts there.
