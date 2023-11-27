# Blade

##### Contracts providing functionality on the blade chain

This directory contains contracts meant for usage on the blade chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## Token Contracts

The `ChildERC20`, `ChildERC721`, `ChildERC1155`, and `NativeERC20` contracts represent templates for the management of bridged assets on the blade chain. The latter two represent assets which are an ERC20 on the connected chain, but used as the native asset (for the payment of gas) on the blade chain. The `NativeERC20` allows for more of the asset to be minted on the child chain directly. The other contracts assume the supply is dictated by the connected chain asset, and cannot mint more of the asset directly. Work is already underway to add Mintable templates for ERC20/721/1155 tokens.

The predicate contracts provide an interface for the bridge to manage transactions involving assets of their respective standards. These are provided in two forms, a regular template and access list version. Supernets can be made permissioned, and the access list versions of the predicate check to see if the address interacting with the bridge has the permissions to do so using either a inclusionary list (AllowList) or exclusionary list (BlockList). Usage of these lists can be turned off at any time by the Supernet's administrators.

## L2StateSender

A simple arbitrary message bridge for sending messages from blade to connected chain.

## State Receiver

This contract represents the blade side of the message bridge.

Data from the connected chain (sent via [`StateSender.sol`](../bridge/StateSender.sol)) is indexed and then signed by validators, and a merkle tree of such data is then submitted to the child chain through the `commit()` function in this contract. Once the merkle tree has been committed, anyone can call the `execute()` function in State Receiver. This means that even though validators will call `execute()` periodically, a user wishing to expedite execution may call it themselves, provided they possess the payload and merkle proof.

## System

A contract template adding various blade-specific addresses, for example, to determine if a call is sent from a client (validator) as a protocol-specific tx (such as bridging data). Precompile addresses are also defined here.

## `validator/`

There is an additional subdirectory with contracts directly relating to block validation, a separate README in that directory describes the contracts there.
