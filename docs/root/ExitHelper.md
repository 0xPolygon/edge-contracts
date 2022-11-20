# ExitHelper

_@QEDK (Polygon Technology)_

> ExitHelper

Helper contract to process exits from stored event roots in CheckpointManager

## Methods

### batchExit

```solidity
function batchExit(ExitHelper.BatchExitInput[] inputs) external nonpayable
```

#### Parameters

| Name   | Type                        | Description |
| ------ | --------------------------- | ----------- |
| inputs | ExitHelper.BatchExitInput[] | undefined   |

### checkpointManager

```solidity
function checkpointManager() external view returns (contract ICheckpointManager)
```

#### Returns

| Name | Type                        | Description |
| ---- | --------------------------- | ----------- |
| \_0  | contract ICheckpointManager | undefined   |

### exit

```solidity
function exit(uint256 blockNumber, uint256 leafIndex, bytes unhashedLeaf, bytes32[] proof) external nonpayable
```

#### Parameters

| Name         | Type      | Description |
| ------------ | --------- | ----------- |
| blockNumber  | uint256   | undefined   |
| leafIndex    | uint256   | undefined   |
| unhashedLeaf | bytes     | undefined   |
| proof        | bytes32[] | undefined   |

### initialize

```solidity
function initialize(contract ICheckpointManager newCheckpointManager) external nonpayable
```

#### Parameters

| Name                 | Type                        | Description |
| -------------------- | --------------------------- | ----------- |
| newCheckpointManager | contract ICheckpointManager | undefined   |

### processedExits

```solidity
function processedExits(uint256) external view returns (bool)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

## Events

### ExitProcessed

```solidity
event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData)
```

#### Parameters

| Name              | Type    | Description |
| ----------------- | ------- | ----------- |
| id `indexed`      | uint256 | undefined   |
| success `indexed` | bool    | undefined   |
| returnData        | bytes   | undefined   |

### Initialized

```solidity
event Initialized(uint8 version)
```

#### Parameters

| Name    | Type  | Description |
| ------- | ----- | ----------- |
| version | uint8 | undefined   |
