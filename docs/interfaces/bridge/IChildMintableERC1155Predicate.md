# IChildMintableERC1155Predicate









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
function onL2StateReceive(uint256 id, address sender, bytes data) external nonpayable
```

Called by exit helper when state is received from L2



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| sender | address | Address of the sender on the child chain |
| data | bytes | Data sent by the sender |

### withdraw

```solidity
function withdraw(contract IChildERC1155 childToken, uint256 tokenId, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | undefined |
| tokenId | uint256 | undefined |
| amount | uint256 | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | undefined |
| receiver | address | undefined |
| tokenId | uint256 | undefined |
| amount | uint256 | undefined |



## Events

### MintableERC1155Deposit

```solidity
event MintableERC1155Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### MintableERC1155DepositBatch

```solidity
event MintableERC1155DepositBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### MintableERC1155Withdraw

```solidity
event MintableERC1155Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### MintableERC1155WithdrawBatch

```solidity
event MintableERC1155WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### MintableTokenMapped

```solidity
event MintableTokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



