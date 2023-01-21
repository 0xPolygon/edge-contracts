# ChildERC20Predicate









## Methods

### DEPOSIT_SIG

```solidity
function DEPOSIT_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### WITHDRAW_SIG

```solidity
function WITHDRAW_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### childTokenTemplate

```solidity
function childTokenTemplate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### deployChildToken

```solidity
function deployChildToken(address rootToken, bytes32 salt, string name, string symbol, uint8 decimals) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | address | undefined |
| salt | bytes32 | undefined |
| name | string | undefined |
| symbol | string | undefined |
| decimals | uint8 | undefined |

### initialize

```solidity
function initialize(contract IStateSender newL2StateSender, address newStateReceiver, address newRootERC20Predicate, address newChildTokenTemplate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | contract IStateSender | undefined |
| newStateReceiver | address | undefined |
| newRootERC20Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |

### l2StateSender

```solidity
function l2StateSender() external view returns (contract IStateSender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStateSender | undefined |

### rootERC20Predicate

```solidity
function rootERC20Predicate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stateReceiver

```solidity
function stateReceiver() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### withdraw

```solidity
function withdraw(contract IChildERC20 childToken, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | undefined |
| amount | uint256 | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC20 childToken, address receiver, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | undefined |
| receiver | address | undefined |
| amount | uint256 | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### L2ERC20Deposit

```solidity
event L2ERC20Deposit(ChildERC20Predicate.ERC20BridgeEvent indexed deposit, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| deposit `indexed` | ChildERC20Predicate.ERC20BridgeEvent | undefined |
| amount  | uint256 | undefined |

### L2ERC20Withdraw

```solidity
event L2ERC20Withdraw(ChildERC20Predicate.ERC20BridgeEvent indexed withdrawal, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawal `indexed` | ChildERC20Predicate.ERC20BridgeEvent | undefined |
| amount  | uint256 | undefined |



