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

### NATIVE_TOKEN_CHILD_ADDRESS

```solidity
function NATIVE_TOKEN_CHILD_ADDRESS() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TOKEN_CONTRACT

```solidity
function NATIVE_TOKEN_CONTRACT() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TRANSFER_PRECOMPILE

```solidity
function NATIVE_TRANSFER_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TRANSFER_PRECOMPILE_GAS

```solidity
function NATIVE_TRANSFER_PRECOMPILE_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### SYSTEM

```solidity
function SYSTEM() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### VALIDATOR_PKCHECK_PRECOMPILE

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### VALIDATOR_PKCHECK_PRECOMPILE_GAS

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### childTokenToRootToken

```solidity
function childTokenToRootToken(address) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC20Predicate, address newChildTokenTemplate, address newNativeTokenRootAddress, string newNativeTokenName, string newNativeTokenSymbol, uint8 newNativeTokenDecimals) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | undefined |
| newStateReceiver | address | undefined |
| newRootERC20Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |
| newNativeTokenRootAddress | address | undefined |
| newNativeTokenName | string | undefined |
| newNativeTokenSymbol | string | undefined |
| newNativeTokenDecimals | uint8 | undefined |

### l2StateSender

```solidity
function l2StateSender() external view returns (contract IStateSender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStateSender | undefined |

### nativeTokenRootAddress

```solidity
function nativeTokenRootAddress() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256, address sender, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

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



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


