# ExitHelper









## Methods

### batchExit

```solidity
function batchExit(IExitHelper.BatchExitInput[] inputs) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| inputs | IExitHelper.BatchExitInput[] | undefined |

### checkpointManager

```solidity
function checkpointManager() external view returns (contract ICheckpointManager)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ICheckpointManager | undefined |

### exit

```solidity
function exit(uint256 blockNumber, uint256 leafIndex, bytes unhashedLeaf, bytes32[] proof) external nonpayable
```

Perform an exit for one event



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | Block number of the exit event on L2 |
| leafIndex | uint256 | Index of the leaf in the exit event Merkle tree |
| unhashedLeaf | bytes | ABI-encoded exit event leaf |
| proof | bytes32[] | Proof of the event inclusion in the tree |

### initialize

```solidity
function initialize(contract ICheckpointManager newCheckpointManager) external nonpayable
```

Initialize the contract with the checkpoint manager address

*The checkpoint manager contract must be deployed first*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newCheckpointManager | contract ICheckpointManager | Address of the checkpoint manager contract |

### processedExits

```solidity
function processedExits(uint256) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### ExitProcessed

```solidity
event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| success `indexed` | bool | undefined |
| returnData  | bytes | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |



