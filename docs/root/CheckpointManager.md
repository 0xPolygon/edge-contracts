# CheckpointManager









## Methods

### DOMAIN

```solidity
function DOMAIN() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### bls

```solidity
function bls() external view returns (contract IBLS)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IBLS | undefined |

### bn256G2

```solidity
function bn256G2() external view returns (contract IBN256G2)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IBN256G2 | undefined |

### chainId

```solidity
function chainId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### checkpointBlockNumbers

```solidity
function checkpointBlockNumbers(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### checkpoints

```solidity
function checkpoints(uint256) external view returns (uint256 epoch, uint256 blockNumber, bytes32 eventRoot)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| epoch | uint256 | undefined |
| blockNumber | uint256 | undefined |
| eventRoot | bytes32 | undefined |

### currentCheckpointBlockNumber

```solidity
function currentCheckpointBlockNumber() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### currentEpoch

```solidity
function currentEpoch() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### currentValidatorSet

```solidity
function currentValidatorSet(uint256) external view returns (address _address, uint256 votingPower)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _address | address | undefined |
| votingPower | uint256 | undefined |

### currentValidatorSetHash

```solidity
function currentValidatorSetHash() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### currentValidatorSetLength

```solidity
function currentValidatorSetLength() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### initialize

```solidity
function initialize(contract IBLS newBls, contract IBN256G2 newBn256G2, uint256 chainId_, ICheckpointManager.Validator[] newValidatorSet) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newBls | contract IBLS | undefined |
| newBn256G2 | contract IBN256G2 | undefined |
| chainId_ | uint256 | undefined |
| newValidatorSet | ICheckpointManager.Validator[] | undefined |

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

### totalVotingPower

```solidity
function totalVotingPower() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |



