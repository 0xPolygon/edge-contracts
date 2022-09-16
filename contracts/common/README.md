# Common

##### Contracts used by both root and child

This directory contains a number of contracts which are used on both the root and child chains. It may have some overlap with `libs/` - `Merkle.sol` could likely be placed in either. (The other contracts in this directory are not actual library contracts, though.)

The contracts in this directory are:

- `BLS.sol`: BLS signature functions
- `BN256G2.sol`: BN256 curve functions (this is the curve we use for BLS)
- `Merkle.sol`: merkle verification
- `Owned.sol`: single address access control with a two-step transfer process

There is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root. We'll provide a high-level overview of the contracts here.

## `BLS.sol`

The BLS contract is used primarily to verify BLS signatures, which are used extensively by validators of the network. BLS signatures have a gas-friendly property which is the ability to verify a signature of aggregated signatures, which cuts down on the number of verifications that need ot be performed on block proposal and attestation drastically.

## `BN256G2.sol`

BLS needs a curve. We use the BN256 curve. This contract exposes the mathematical functions needed to interact with the curve.

## `Merkle.sol`

Merkle trees are a common form of compressing verification data in the suite. This contract exposes a function for verifying that a given leaf is a part of a merkle tree (given the root and proof).

## `Owned.sol`

Similar to OpenZeppelin's well-known `Ownable`, `Owned` provides a template for functions to have their access locked to a `msg.sender` single address. The primary difference is that OZ's `Ownable` has a one-step ownership transferral process - the current owner calls `transferOwnership` and transfers to the new owner. This contract uses a two-step process similar to those found in a number of other popular projects where first the current owner proposes a new owner, and then the new owner can accept ownership. This reduces the likelihood of mishap due to error in the input address.
