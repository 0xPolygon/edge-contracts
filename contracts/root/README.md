# Root

##### Contracts providing functionality on the root chain

This directory contains contracts meant for usage on the root chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## Checkpoint Manager

Used for receiving messages on root frpom chain. Batches of blocks and an event root are received from validators, then the message payloads are executed.

different than state sender since this receives from L2, whereas state sender _sends_ to L2

separated out since unlike on child, here user is expected to execute

## State Sender

Sends messages to child. Messages are indexed by validators from root and then signed. Once they have enough signatures they can be committed on `StateReceiver` on child.

Unlike the current implementation of child, sending and receiving messages is split into two contracts on root.

## Root Validator Set

Contract for managing validator data committed to root. **It is extremely likely that this contract will change in the future.**
