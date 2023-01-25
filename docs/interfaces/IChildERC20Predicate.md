# IChildERC20Predicate









## Methods

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




