# RootERC721Predicate









## Methods

### DEPOSIT_BATCH_SIG

```solidity
function DEPOSIT_BATCH_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### DEPOSIT_SIG

```solidity
function DEPOSIT_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### MAP_TOKEN_SIG

```solidity
function MAP_TOKEN_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### WITHDRAW_BATCH_SIG

```solidity
function WITHDRAW_BATCH_SIG() external view returns (bytes32)
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

### childERC721Predicate

```solidity
function childERC721Predicate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### childTokenTemplate

```solidity
function childTokenTemplate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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
function initialize(address newStateSender, address newExitHelper, address newChildERC721Predicate, address newChildTokenTemplate) external nonpayable
```

Initilization function for RootERC721Predicate

*Can only be called once.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newStateSender | address | Address of StateSender to send deposit information to |
| newExitHelper | address | Address of ExitHelper to receive withdrawal information from |
| newChildERC721Predicate | address | Address of child ERC721 predicate to communicate with |
| newChildTokenTemplate | address | undefined |

### mapToken

```solidity
function mapToken(contract IERC721Metadata rootToken) external nonpayable returns (address)
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
| _0 | address | Address of the mapped child token |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

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

### rootTokenToChildToken

```solidity
function rootTokenToChildToken(address) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stateSender

```solidity
function stateSender() external view returns (contract IStateSender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStateSender | undefined |



## Events

### ERC721Deposit

```solidity
event ERC721Deposit(address indexed rootToken, address indexed childToken, address depositor, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### ERC721DepositBatch

```solidity
event ERC721DepositBatch(address indexed rootToken, address indexed childToken, address indexed depositor, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### ERC721Withdraw

```solidity
event ERC721Withdraw(address indexed rootToken, address indexed childToken, address withdrawer, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### ERC721WithdrawBatch

```solidity
event ERC721WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed withdrawer, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### TokenMapped

```solidity
event TokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



