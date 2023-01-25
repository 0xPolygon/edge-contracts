# EIP1559Burn









## Methods

### burnDestination

```solidity
function burnDestination() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### childERC20Predicate

```solidity
function childERC20Predicate() external view returns (contract IChildERC20Predicate)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IChildERC20Predicate | undefined |

### initialize

```solidity
function initialize(contract IChildERC20Predicate newChildERC20Predicate, address newBurnDestination) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newChildERC20Predicate | contract IChildERC20Predicate | undefined |
| newBurnDestination | address | undefined |

### withdraw

```solidity
function withdraw() external nonpayable
```








## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### NativeTokenBurnt

```solidity
event NativeTokenBurnt(address indexed burner, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| burner `indexed` | address | undefined |
| amount  | uint256 | undefined |



