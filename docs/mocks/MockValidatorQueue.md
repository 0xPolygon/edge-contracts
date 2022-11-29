# MockValidatorQueue









## Methods

### getIndex

```solidity
function getIndex(address validator) external view returns (uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### getQueue

```solidity
function getQueue() external view returns (struct QueuedValidator[])
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | QueuedValidator[] | undefined |

### reset

```solidity
function reset() external nonpayable
```






### stake

```solidity
function stake(address validator, uint256 stake_, uint256 delegation) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| stake_ | uint256 | undefined |
| delegation | uint256 | undefined |

### unstake

```solidity
function unstake(address validator, uint256 stake_, uint256 delegation) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| stake_ | uint256 | undefined |
| delegation | uint256 | undefined |




