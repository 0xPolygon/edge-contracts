# StateSender









## Methods

### MAX_LENGTH

```solidity
function MAX_LENGTH() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### counter

```solidity
function counter() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initializeOnMigration

```solidity
function initializeOnMigration(uint256 lastId) external nonpayable
```

initializer for StateSender, sets the initial id for state sync events



#### Parameters

| Name | Type | Description |
|---|---|---|
| lastId | uint256 | last state sync id on old contract |

### syncState

```solidity
function syncState(address receiver, bytes data) external nonpayable
```

Generates sync state event based on receiver and data. Anyone can call this method to emit an event. Receiver on Polygon should add check based on sender.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | Receiver address on Polygon chain |
| data | bytes | Data to send on Polygon chain |



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

### StateSynced

```solidity
event StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| sender `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| data  | bytes | undefined |



