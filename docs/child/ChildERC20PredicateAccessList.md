# ChildERC20PredicateAccessList

*Polygon Technology (@QEDK)*

> ChildERC20PredicateAccessList

Enables ERC20 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain



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

### WITHDRAW_SIG

```solidity
function WITHDRAW_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### acceptOwnership

```solidity
function acceptOwnership() external nonpayable
```



*The new owner accepts the ownership transfer.*


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
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC20Predicate, address newChildTokenTemplate, address newNativeTokenRootAddress) external nonpayable
```

Initilization function for ChildERC20Predicate

*Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | Address of L2StateSender to send exit information to |
| newStateReceiver | address | Address of StateReceiver to receive deposit information from |
| newRootERC20Predicate | address | Address of root ERC20 predicate to communicate with |
| newChildTokenTemplate | address | Address of child token implementation to deploy clones of |
| newNativeTokenRootAddress | address | Address of native token on root chain |

### initialize

```solidity
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC20Predicate, address newChildTokenTemplate, address newNativeTokenRootAddress, bool newUseAllowList, bool newUseBlockList, address newOwner) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | undefined |
| newStateReceiver | address | undefined |
| newRootERC20Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |
| newNativeTokenRootAddress | address | undefined |
| newUseAllowList | bool | undefined |
| newUseBlockList | bool | undefined |
| newOwner | address | undefined |

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

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### pendingOwner

```solidity
function pendingOwner() external view returns (address)
```



*Returns the address of the pending owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### rootERC20Predicate

```solidity
function rootERC20Predicate() external view returns (address)
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

### setAllowList

```solidity
function setAllowList(bool newUseAllowList) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newUseAllowList | bool | undefined |

### setBlockList

```solidity
function setBlockList(bool newUseBlockList) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newUseBlockList | bool | undefined |

### stateReceiver

```solidity
function stateReceiver() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### withdraw

```solidity
function withdraw(contract IChildERC20 childToken, uint256 amount) external nonpayable
```

Function to withdraw tokens from the withdrawer to themselves on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | Address of the child token being withdrawn |
| amount | uint256 | Amount to withdraw |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC20 childToken, address receiver, uint256 amount) external nonpayable
```

Function to withdraw tokens from the withdrawer to another address on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | Address of the child token being withdrawn |
| receiver | address | Address of the receiver on the root chain |
| amount | uint256 | Amount to withdraw |



## Events

### AllowListUsageSet

```solidity
event AllowListUsageSet(uint256 indexed block, bool indexed status)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| block `indexed` | uint256 | undefined |
| status `indexed` | bool | undefined |

### BlockListUsageSet

```solidity
event BlockListUsageSet(uint256 indexed block, bool indexed status)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| block `indexed` | uint256 | undefined |
| status `indexed` | bool | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### L2ERC20Deposit

```solidity
event L2ERC20Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| amount  | uint256 | undefined |

### L2ERC20Withdraw

```solidity
event L2ERC20Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| amount  | uint256 | undefined |

### L2TokenMapped

```solidity
event L2TokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |

### OwnershipTransferStarted

```solidity
event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


