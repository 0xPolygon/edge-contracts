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

### checkpoints

```solidity
function checkpoints(uint256) external view returns (uint256 startBlock, uint256 endBlock, bytes32 eventRoot)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name       | Type    | Description |
| ---------- | ------- | ----------- |
| startBlock | uint256 | undefined   |
| endBlock   | uint256 | undefined   |
| eventRoot  | bytes32 | undefined   |

### currentCheckpointId

```solidity
function currentCheckpointId() external view returns (uint256)
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
function initialize(contract IBLS newBls, contract IBN256G2 newBn256G2, contract IRootValidatorSet newRootValidatorSet, bytes32 newDomain) external nonpayable
```

Initialization function for CheckpointManager

_Contract can only be initialized once_

#### Parameters

| Name                | Type                       | Description                                            |
| ------------------- | -------------------------- | ------------------------------------------------------ |
| newBls              | contract IBLS              | Address of the BLS library contract                    |
| newBn256G2          | contract IBN256G2          | Address of the BLS library contract                    |
| newRootValidatorSet | contract IRootValidatorSet | Array of validator addresses to seed the contract with |
| newDomain           | bytes32                    | Domain to use when hashing messages to a point         |

### rootValidatorSet

```solidity
function rootValidatorSet() external view returns (contract IRootValidatorSet)
```

#### Returns

| Name | Type                       | Description |
| ---- | -------------------------- | ----------- |
| \_0  | contract IRootValidatorSet | undefined   |

### submit

```solidity
function submit(uint256 id, CheckpointManager.Checkpoint checkpoint, uint256[2] signature, uint256[] validatorIds, IRootValidatorSet.Validator[] newValidators) external nonpayable
```

#### Parameters

| Name          | Type                          | Description |
| ------------- | ----------------------------- | ----------- |
| id            | uint256                       | undefined   |
| checkpoint    | CheckpointManager.Checkpoint  | undefined   |
| signature     | uint256[2]                    | undefined   |
| validatorIds  | uint256[]                     | undefined   |
| newValidators | IRootValidatorSet.Validator[] | undefined   |

### submitBatch

```solidity
function submitBatch(uint256[] ids, CheckpointManager.Checkpoint[] checkpointBatch, uint256[2] signature, uint256[] validatorIds, IRootValidatorSet.Validator[] newValidators) external nonpayable
```

#### Parameters

| Name            | Type                           | Description |
| --------------- | ------------------------------ | ----------- |
| ids             | uint256[]                      | undefined   |
| checkpointBatch | CheckpointManager.Checkpoint[] | undefined   |
| signature       | uint256[2]                     | undefined   |
| validatorIds    | uint256[]                      | undefined   |
| newValidators   | IRootValidatorSet.Validator[]  | undefined   |

## Events

### Initialized

```solidity
event Initialized(uint8 version)
```

#### Parameters

| Name    | Type  | Description |
| ------- | ----- | ----------- |
| version | uint8 | undefined   |

### NewCheckpoint

```solidity
event NewCheckpoint(uint256 checkpointId)
```

#### Parameters

| Name         | Type    | Description |
| ------------ | ------- | ----------- |
| checkpointId | uint256 | undefined   |
