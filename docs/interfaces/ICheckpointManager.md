# ICheckpointManager









## Methods

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

### initialize

```solidity
function initialize(contract IBLS newBls, contract IBN256G2 newBn256G2, bytes32 newDomain, Validator[] newValidatorSet) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newBls | contract IBLS | undefined |
| newBn256G2 | contract IBN256G2 | undefined |
| newDomain | bytes32 | undefined |
| newValidatorSet | Validator[] | undefined |

### submit

```solidity
function submit(uint256 chainId, CheckpointMetadata checkpointMetadata, Checkpoint checkpoint, uint256[2] signature, Validator[] newValidatorSet, bytes bitmap) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| chainId | uint256 | undefined |
| checkpointMetadata | CheckpointMetadata | undefined |
| checkpoint | Checkpoint | undefined |
| signature | uint256[2] | undefined |
| newValidatorSet | Validator[] | undefined |
| bitmap | bytes | undefined |




