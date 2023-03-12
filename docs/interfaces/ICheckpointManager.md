# ICheckpointManager

*Polygon Technology*

> CheckpointManager

Checkpoint manager contract used by validators to submit signed checkpoints as proof of canonical chain.

*The contract is used to submit checkpoints and verify that they have been signed as expected.*

## Methods

### getCheckpointBlock

```solidity
function getCheckpointBlock(uint256 blockNumber) external view returns (bool, uint256)
```

Function to get the checkpoint block number for a block number. It finds block number which is greater or equal than provided one in checkpointBlockNumbers array.



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | The block number to get the checkpoint block number for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool If block number was checkpointed |
| _1 | uint256 | uint256 The checkpoint block number |

### getEventMembershipByBlockNumber

```solidity
function getEventMembershipByBlockNumber(uint256 blockNumber, bytes32 leaf, uint256 leafIndex, bytes32[] proof) external view returns (bool)
```

Function to get if a event is part of the event root for a block number



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | The block number to get the event root from (i.e. blockN &lt;-- eventRoot --&gt; blockN+M) |
| leaf | bytes32 | The leaf of the event (keccak256-encoded log) |
| leafIndex | uint256 | The leaf index of the event in the Merkle root tree |
| proof | bytes32[] | The proof for leaf membership in the event root tree |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getEventMembershipByEpoch

```solidity
function getEventMembershipByEpoch(uint256 epoch, bytes32 leaf, uint256 leafIndex, bytes32[] proof) external view returns (bool)
```

Function to get if a event is part of the event root for an epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epoch | uint256 | The epoch id to get the event root for |
| leaf | bytes32 | The leaf of the event (keccak256-encoded log) |
| leafIndex | uint256 | The leaf index of the event in the Merkle root tree |
| proof | bytes32[] | The proof for leaf membership in the event root tree |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getEventRootByBlock

```solidity
function getEventRootByBlock(uint256 blockNumber) external view returns (bytes32)
```

Function to get the event root for a block number



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | The block number to get the event root for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### submit

```solidity
function submit(ICheckpointManager.CheckpointMetadata checkpointMetadata, ICheckpointManager.Checkpoint checkpoint, uint256[2] signature, ICheckpointManager.Validator[] newValidatorSet, bytes bitmap) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| checkpointMetadata | ICheckpointManager.CheckpointMetadata | undefined |
| checkpoint | ICheckpointManager.Checkpoint | undefined |
| signature | uint256[2] | undefined |
| newValidatorSet | ICheckpointManager.Validator[] | undefined |
| bitmap | bytes | undefined |




