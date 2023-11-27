# IChildMintableERC721Predicate









## Methods

### initialize

```solidity
function initialize(address newStateSender, address newExitHelper, address newRootERC721Predicate, address newChildTokenTemplate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newStateSender | address | undefined |
| newExitHelper | address | undefined |
| newRootERC721Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |

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



## Events

### MintableERC721Deposit

```solidity
event MintableERC721Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### MintableERC721DepositBatch

```solidity
event MintableERC721DepositBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### MintableERC721Withdraw

```solidity
event MintableERC721Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### MintableERC721WithdrawBatch

```solidity
event MintableERC721WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### MintableTokenMapped

```solidity
event MintableTokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



