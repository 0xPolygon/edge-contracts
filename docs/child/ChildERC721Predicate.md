# ChildERC721Predicate

*Polygon Technology (@QEDK, @wschwab)*

> ChildERC721Predicate

Enables ERC721 token deposits and withdrawals across an arbitrary root chain and child chain



## Methods

### ALLOWLIST_PRECOMPILE

```solidity
function ALLOWLIST_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### BLOCKLIST_PRECOMPILE

```solidity
function BLOCKLIST_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### READ_ADDRESSLIST_GAS

```solidity
function READ_ADDRESSLIST_GAS() external view returns (uint256)
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

### childTokenTemplate

```solidity
function childTokenTemplate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### initialize

```solidity
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC721Predicate, address newChildTokenTemplate) external nonpayable
```

Initilization function for ChildERC721Predicate

*Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | Address of L2StateSender to send exit information to |
| newStateReceiver | address | Address of StateReceiver to receive deposit information from |
| newRootERC721Predicate | address | Address of root ERC721 predicate to communicate with |
| newChildTokenTemplate | address | Address of child token implementation to deploy clones of |

### l2StateSender

```solidity
function l2StateSender() external view returns (contract IStateSender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStateSender | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256, address sender, bytes data) external nonpayable
```

Function to be used for token deposits

*Can be extended to include other signatures for more functionality*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | Address of the sender on the root chain |
| data | bytes | Data sent by the sender |

### rootERC721Predicate

```solidity
function rootERC721Predicate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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
function withdraw(contract IChildERC721 childToken, uint256 tokenId) external nonpayable
```

Function to withdraw tokens from the withdrawer to themselves on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | Address of the child token being withdrawn |
| tokenId | uint256 | index of the NFT to withdraw |

### withdrawBatch

```solidity
function withdrawBatch(contract IChildERC721 childToken, address[] receivers, uint256[] tokenIds) external nonpayable
```

Function to batch withdraw tokens from the withdrawer to other addresses on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | Address of the child token being withdrawn |
| receivers | address[] | Addresses of the receivers on the root chain |
| tokenIds | uint256[] | indices of the NFTs to withdraw |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC721 childToken, address receiver, uint256 tokenId) external nonpayable
```

Function to withdraw tokens from the withdrawer to another address on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | Address of the child token being withdrawn |
| receiver | address | Address of the receiver on the root chain |
| tokenId | uint256 | index of the NFT to withdraw |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### L2ERC721Deposit

```solidity
event L2ERC721Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### L2ERC721DepositBatch

```solidity
event L2ERC721DepositBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### L2ERC721Withdraw

```solidity
event L2ERC721Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### L2ERC721WithdrawBatch

```solidity
event L2ERC721WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### L2TokenMapped

```solidity
event L2TokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


