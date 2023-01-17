# MockValidatorStorage









## Methods

### ACTIVE_VALIDATORS

```solidity
function ACTIVE_VALIDATORS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### activeValidators

```solidity
function activeValidators() external view returns (address[])
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### allValidators

```solidity
function allValidators() external view returns (address[])
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256 balance)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| balance | uint256 | undefined |

### insert

```solidity
function insert(address account, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| amount | uint256 | undefined |

### max

```solidity
function max() external view returns (address account, uint256 balance)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| balance | uint256 | undefined |

### min

```solidity
function min() external view returns (address account, uint256 balance)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| balance | uint256 | undefined |

### remove

```solidity
function remove(address account) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |




## Errors

### AmountZero

```solidity
error AmountZero()
```






### Exists

```solidity
error Exists(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

### NotFound

```solidity
error NotFound(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |


