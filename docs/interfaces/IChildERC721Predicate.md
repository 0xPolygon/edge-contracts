# IChildERC721Predicate









## Methods

### deployChildToken

```solidity
function deployChildToken(address rootToken, bytes32 salt, string name, string symbol) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | address | undefined |
| salt | bytes32 | undefined |
| name | string | undefined |
| symbol | string | undefined |

### initialize

```solidity
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC721Predicate, address newChildTokenTemplate, address newNativeTokenRootAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | undefined |
| newStateReceiver | address | undefined |
| newRootERC721Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |
| newNativeTokenRootAddress | address | undefined |

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
function withdraw(contract IChildERC721 childToken, uint256 tokenId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | undefined |
| tokenId | uint256 | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC721 childToken, address receiver, uint256 tokenId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | undefined |
| receiver | address | undefined |
| tokenId | uint256 | undefined |




