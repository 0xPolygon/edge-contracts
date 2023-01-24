# RootERC20Predicate









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

### childERC20Predicate

```solidity
function childERC20Predicate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### deposit

```solidity
function deposit(contract IERC20 rootToken, address childToken, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20 | undefined |
| childToken | address | undefined |
| amount | uint256 | undefined |

### depositTo

```solidity
function depositTo(contract IERC20 rootToken, address childToken, address receiver, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20 | undefined |
| childToken | address | undefined |
| receiver | address | undefined |
| amount | uint256 | undefined |

### exitHelper

```solidity
function exitHelper() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### initialize

```solidity
function initialize(address newStateSender, address newExitHelper, address newChildERC20Predicate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newStateSender | address | undefined |
| newExitHelper | address | undefined |
| newChildERC20Predicate | address | undefined |

### onL2StateReceive

```solidity
function onL2StateReceive(uint256, address sender, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

### stateSender

```solidity
function stateSender() external view returns (contract IStateSender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStateSender | undefined |



## Events

### ERC20Deposit

```solidity
event ERC20Deposit(RootERC20Predicate.ERC20BridgeEvent indexed deposit, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| deposit `indexed` | RootERC20Predicate.ERC20BridgeEvent | undefined |
| amount  | uint256 | undefined |

### ERC20Withdraw

```solidity
event ERC20Withdraw(RootERC20Predicate.ERC20BridgeEvent indexed withdrawal, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawal `indexed` | RootERC20Predicate.ERC20BridgeEvent | undefined |
| amount  | uint256 | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |



