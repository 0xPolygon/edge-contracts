# IRootMintableERC721Predicate









## Methods

### deposit

```solidity
function deposit(contract IERC721Metadata rootToken, uint256 tokenId) external nonpayable
```

Function to deposit tokens from the depositor to themselves on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC721Metadata | Address of the root token being deposited |
| tokenId | uint256 | Index of the NFT to deposit |

### depositBatch

```solidity
function depositBatch(contract IERC721Metadata rootToken, address[] receivers, uint256[] tokenIds) external nonpayable
```

Function to deposit tokens from the depositor to other addresses on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC721Metadata | Address of the root token being deposited |
| receivers | address[] | Addresses of the receivers on the child chain |
| tokenIds | uint256[] | Indeices of the NFTs to deposit |

### depositTo

```solidity
function depositTo(contract IERC721Metadata rootToken, address receiver, uint256 tokenId) external nonpayable
```

Function to deposit tokens from the depositor to another address on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC721Metadata | Address of the root token being deposited |
| receiver | address | undefined |
| tokenId | uint256 | Index of the NFT to deposit |

### mapToken

```solidity
function mapToken(contract IERC721Metadata rootToken) external nonpayable returns (address childToken)
```

Function to be used for token mapping

*Called internally on deposit if token is not mapped already*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC721Metadata | Address of the root token to map |

#### Returns

| Name | Type | Description |
|---|---|---|
| childToken | address | Address of the mapped child token |

### onStateReceive

```solidity
function onStateReceive(uint256 counter, address sender, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |



## Events

### L2MintableERC721Deposit

```solidity
event L2MintableERC721Deposit(address indexed rootToken, address indexed childToken, address depositor, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### L2MintableERC721DepositBatch

```solidity
event L2MintableERC721DepositBatch(address indexed rootToken, address indexed childToken, address indexed depositor, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### L2MintableERC721Withdraw

```solidity
event L2MintableERC721Withdraw(address indexed rootToken, address indexed childToken, address withdrawer, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### L2MintableERC721WithdrawBatch

```solidity
event L2MintableERC721WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed withdrawer, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### L2MintableTokenMapped

```solidity
event L2MintableTokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



