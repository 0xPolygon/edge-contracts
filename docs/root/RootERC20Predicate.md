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

Function to deposit tokens from the depositor to themselves on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20 | Address of the root token being deposited |
| childToken | address | Address of the child token |
| amount | uint256 | Amount to deposit |

### depositTo

```solidity
function depositTo(contract IERC20 rootToken, address childToken, address receiver, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to another address on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20 | Address of the root token being deposited |
| childToken | address | Address of the child token |
| receiver | address | undefined |
| amount | uint256 | Amount to deposit |

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

Initilization function for RootERC20Predicate

*Can only be called once.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newStateSender | address | Address of StateSender to send deposit information to |
| newExitHelper | address | Address of ExitHelper to receive withdrawal information from |
| newChildERC20Predicate | address | Address of child ERC20 predicate to communicate with |

### onL2StateReceive

```solidity
function onL2StateReceive(uint256, address sender, bytes data) external nonpayable
```

Function to be used for token withdrawals

*Can be extended to include other signatures for more functionality*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | Address of the sender on the child chain |
| data | bytes | Data sent by the sender |

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



