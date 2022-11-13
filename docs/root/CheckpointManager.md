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
