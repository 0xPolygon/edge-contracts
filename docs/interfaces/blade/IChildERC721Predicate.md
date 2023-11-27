# IChildERC721Predicate









## Methods

### initialize

```solidity
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC721Predicate, address newChildTokenTemplate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | undefined |
| newStateReceiver | address | undefined |
| newRootERC721Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |

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

### withdrawBatch

```solidity
function withdrawBatch(contract IChildERC721 childToken, address[] receivers, uint256[] tokenIds) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | undefined |
| receivers | address[] | undefined |
| tokenIds | uint256[] | undefined |

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




