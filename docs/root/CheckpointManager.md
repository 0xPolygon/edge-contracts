# CheckpointManager

_Polygon Technology_

> CheckpointManager

Checkpoint manager contract used by validators to submit signed checkpoints as proof of canonical chain.

_The contract is used to submit checkpoints and verify that they have been signed as expected._

## Methods

### bls

```solidity
function bls() external view returns (contract IBLS)
```

#### Returns

| Name | Type          | Description |
| ---- | ------------- | ----------- |
| \_0  | contract IBLS | undefined   |

### bn256G2

```solidity
function bn256G2() external view returns (contract IBN256G2)
```

#### Returns

| Name | Type              | Description |
| ---- | ----------------- | ----------- |
| \_0  | contract IBN256G2 | undefined   |

### checkpointEndBlocks

```solidity
function checkpointEndBlocks(uint256) external view returns (uint256)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### checkpoints

```solidity
function checkpoints(uint256) external view returns (uint256 endBlock, bytes32 eventRoot)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| endBlock  | uint256 | undefined   |
| eventRoot | bytes32 | undefined   |

### currentCheckpointId

```solidity
function currentCheckpointId() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### currentValidatorSet

```solidity
function currentValidatorSet(uint256) external view returns (address _address, uint256 votingPower)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name        | Type    | Description |
| ----------- | ------- | ----------- |
| \_address   | address | undefined   |
| votingPower | uint256 | undefined   |

### currentValidatorSetLength

```solidity
function currentValidatorSetLength() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### domain

```solidity
function domain() external view returns (bytes32)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | bytes32 | undefined   |

### getEventMembershipByBlockNumber

```solidity
function getEventMembershipByBlockNumber(uint256 blockNumber, bytes32 leaf, uint256 leafIndex, bytes32[] proof) external view returns (bool)
```

Function to get if a event is part of the event root for a block number

#### Parameters

| Name        | Type      | Description                                                                                |
| ----------- | --------- | ------------------------------------------------------------------------------------------ |
| blockNumber | uint256   | The block number to get the event root from (i.e. blockN &lt;-- eventRoot --&gt; blockN+M) |
| leaf        | bytes32   | The leaf of the event (keccak256-encoded log)                                              |
| leafIndex   | uint256   | The leaf index of the event in the Merkle root tree                                        |
| proof       | bytes32[] | The proof for leaf membership in the event root tree                                       |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

### getEventMembershipByCheckpointId

```solidity
function getEventMembershipByCheckpointId(uint256 checkpointId, bytes32 leaf, uint256 leafIndex, bytes32[] proof) external view returns (bool)
```

Function to get if a event is part of the event root for a checkpoint id

#### Parameters

| Name         | Type      | Description                                          |
| ------------ | --------- | ---------------------------------------------------- |
| checkpointId | uint256   | The checkpoint id to get the event root from         |
| leaf         | bytes32   | The leaf of the event (keccak256-encoded log)        |
| leafIndex    | uint256   | The leaf index of the event in the Merkle root tree  |
| proof        | bytes32[] | The proof for leaf membership in the event root tree |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

### getEventRootByBlock

```solidity
function getEventRootByBlock(uint256 blockNumber) external view returns (bytes32)
```

Function to get the event root for a block number

#### Parameters

| Name        | Type    | Description                                |
| ----------- | ------- | ------------------------------------------ |
| blockNumber | uint256 | The block number to get the event root for |

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | bytes32 | undefined   |

### initialize

```solidity
function initialize(contract IBLS newBls, contract IBN256G2 newBn256G2, bytes32 newDomain, CheckpointManager.Validator[] newValidatorSet) external nonpayable
```

#### Parameters

| Name            | Type                          | Description |
| --------------- | ----------------------------- | ----------- |
| newBls          | contract IBLS                 | undefined   |
| newBn256G2      | contract IBN256G2             | undefined   |
| newDomain       | bytes32                       | undefined   |
| newValidatorSet | CheckpointManager.Validator[] | undefined   |

### submit

```solidity
function submit(uint256 chainId, CheckpointManager.CheckpointMetadata checkpointMetadata, CheckpointManager.Checkpoint checkpoint, uint256[2] signature, CheckpointManager.Validator[] newValidatorSet, bytes bitmap) external nonpayable
```

#### Parameters

| Name               | Type                                 | Description |
| ------------------ | ------------------------------------ | ----------- |
| chainId            | uint256                              | undefined   |
| checkpointMetadata | CheckpointManager.CheckpointMetadata | undefined   |
| checkpoint         | CheckpointManager.Checkpoint         | undefined   |
| signature          | uint256[2]                           | undefined   |
| newValidatorSet    | CheckpointManager.Validator[]        | undefined   |
| bitmap             | bytes                                | undefined   |

### submitBatch

```solidity
function submitBatch(uint256 chainId, CheckpointManager.CheckpointMetadata[] checkpointMetadata, CheckpointManager.Checkpoint[] checkpointBatch, uint256[2] signature, CheckpointManager.Validator[] newValidatorSet, bytes bitmap) external nonpayable
```

#### Parameters

| Name               | Type                                   | Description |
| ------------------ | -------------------------------------- | ----------- |
| chainId            | uint256                                | undefined   |
| checkpointMetadata | CheckpointManager.CheckpointMetadata[] | undefined   |
| checkpointBatch    | CheckpointManager.Checkpoint[]         | undefined   |
| signature          | uint256[2]                             | undefined   |
| newValidatorSet    | CheckpointManager.Validator[]          | undefined   |
| bitmap             | bytes                                  | undefined   |

## Events

### Initialized

```solidity
event Initialized(uint8 version)
```

#### Parameters

| Name    | Type  | Description |
| ------- | ----- | ----------- |
| version | uint8 | undefined   |
