# RootERC1155Predicate









## Methods

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

### WITHDRAW_SIG

```solidity
function WITHDRAW_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### childERC1155Predicate

```solidity
function childERC1155Predicate() external view returns (address)
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
function deposit(contract IERC1155MetadataURI rootToken, uint256 id, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to themselves on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| id | uint256 | Index of the NFT to deposit |
| amount | uint256 | Amount to deposit |

### depositTo

```solidity
function depositTo(contract IERC1155MetadataURI rootToken, address receiver, uint256 id, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to another address on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| receiver | address | undefined |
| id | uint256 | Index of the NFT to deposit |
| amount | uint256 | Amount to deposit |

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
function initialize(address newStateSender, address newExitHelper, address newChildERC1155Predicate, address newChildTokenTemplate, address nativeTokenRootAddress) external nonpayable
```

Initilization function for RootERC1155Predicate

*Can only be called once.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newStateSender | address | Address of StateSender to send deposit information to |
| newExitHelper | address | Address of ExitHelper to receive withdrawal information from |
| newChildERC1155Predicate | address | Address of child ERC1155 predicate to communicate with |
| newChildTokenTemplate | address | undefined |
| nativeTokenRootAddress | address | undefined |

### mapToken

```solidity
function mapToken(contract IERC1155MetadataURI rootToken) external nonpayable
```

Function to be used for token mapping

*Called internally on deposit if token is not mapped already*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token to map |

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

### ERC1155Deposit

```solidity
event ERC1155Deposit(address indexed rootToken, address indexed childToken, address depositor, address indexed receiver, uint256 id, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor  | address | undefined |
| receiver `indexed` | address | undefined |
| id  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155Withdraw

```solidity
event ERC1155Withdraw(address indexed rootToken, address indexed childToken, address withdrawer, address indexed receiver, uint256 id, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer  | address | undefined |
| receiver `indexed` | address | undefined |
| id  | uint256 | undefined |
| amount  | uint256 | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```





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



