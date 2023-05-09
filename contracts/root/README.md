# Root

##### Contracts providing functionality on the root chain

This directory contains contracts meant for usage on the root chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## Checkpoint Manager

Used for receiving messages on the root chain. Batches of blocks and an event root are received from validators, then the message payloads are executed. This is different than state sender since this receives from L2, whereas state sender _sends_ to L2. This requires a separate contract since the user is expected to execute after the state is received, unlike on child.

## State Sender

Sends messages to child. Messages are indexed by validators from root and then signed. Once they have enough signatures they can be committed on `StateReceiver` on child.

Unlike the current implementation of child, sending and receiving messages is split into two contracts on root.

## `staking/`

There is an additional subdirectory with contracts directly relating to Supernet managers, or contracts meant as a hub on root for all child chains. A separate README in that directory describes the contracts there.
