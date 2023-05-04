# SupernetManager









## Methods

### id

```solidity
function id() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### onInit

```solidity
function onInit(uint256 id_) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id_ | uint256 | undefined |

### onStake

```solidity
function onStake(address validator, uint256 amount) external nonpayable
```

called when a validator stakes



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| amount | uint256 | undefined |



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



