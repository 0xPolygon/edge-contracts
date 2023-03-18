# IRootERC1155Predicate









## Methods

### deposit

```solidity
function deposit(contract IERC1155MetadataURI rootToken, uint256 tokenId, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to themselves on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| tokenId | uint256 | Index of the NFT to deposit |
| amount | uint256 | Amount to deposit |

### depositBatch

```solidity
function depositBatch(contract IERC1155MetadataURI rootToken, address[] receivers, uint256[] tokenIds, uint256[] amounts) external nonpayable
```

Function to deposit tokens from the depositor to other addresses on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| receivers | address[] | Addresses of the receivers on the child chain |
| tokenIds | uint256[] | Indeices of the NFTs to deposit |
| amounts | uint256[] | Amounts to deposit |

### depositTo

```solidity
function depositTo(contract IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to another address on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| receiver | address | undefined |
| tokenId | uint256 | Index of the NFT to deposit |
| amount | uint256 | Amount to deposit |

### mapToken

```solidity
function mapToken(contract IERC1155MetadataURI rootToken) external nonpayable returns (address childToken)
```

Function to be used for token mapping

*Called internally on deposit if token is not mapped already*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token to map |

#### Returns

| Name | Type | Description |
|---|---|---|
| childToken | address | Address of the mapped child token |



## Events

### ERC1155Deposit

```solidity
event ERC1155Deposit(address indexed rootToken, address indexed childToken, address depositor, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155DepositBatch

```solidity
event ERC1155DepositBatch(address indexed rootToken, address indexed childToken, address indexed depositor, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### ERC1155Withdraw

```solidity
event ERC1155Withdraw(address indexed rootToken, address indexed childToken, address withdrawer, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155WithdrawBatch

```solidity
event ERC1155WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed withdrawer, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### TokenMapped

```solidity
event TokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



