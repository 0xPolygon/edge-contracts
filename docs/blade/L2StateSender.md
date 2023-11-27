# L2StateSender

*Polygon Technology (@QEDK)*

> L2StateSender

Arbitrary message passing contract from L2 -&gt; L1

*There is no transaction execution on L1, only a commitment of the emitted events are stored*

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

### syncState

```solidity
function syncState(address receiver, bytes data) external nonpayable
```

Emits an event which is indexed by v3 validators and submitted as a commitment on L1 allowing for lazy execution



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | Address of the message recipient on L1 |
| data | bytes | Data to use in message call to recipient |



## Events

### L2StateSynced

```solidity
event L2StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| sender `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| data  | bytes | undefined |



