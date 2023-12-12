# BladeManager









## Methods

### acceptOwnership

```solidity
function acceptOwnership() external nonpayable
```



*The new owner accepts the ownership transfer.*


### addGenesisBalance

```solidity
function addGenesisBalance(uint256 nonStakeAmount, uint256 stakeAmount) external nonpayable
```

addGenesisBalance is used to specGenesisAccountnce information for genesis accounts on a  Blade chain. It is applicable only in case Blade native contract is mapped to a pre-existing rootchain ERC20 token.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nonStakeAmount | uint256 | represents the amount to be premined in the genesis which is not staked. |
| stakeAmount | uint256 | represents the amount to be premined in genesis which is going to be staked. |

### finalizeGenesis

```solidity
function finalizeGenesis() external nonpayable
```

GenesisAccounts initial genesis validator set

*only callable by owner*


### genesisSet

```solidity
function genesisSet() external view returns (struct GenesisAccount[])
```

returns the genesis validator set with their balances




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | GenesisAccount[] | undefined |

### initialize

```solidity
function initialize(address newRootERC20Predicate, GenesisAccount[] genesisAccounts) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRootERC20Predicate | address | undefined |
| genesisAccounts | GenesisAccount[] | undefined |

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



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### GenesisBalanceAdded

```solidity
event GenesisBalanceAdded(address indexed account, uint256 indexed amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| amount `indexed` | uint256 | undefined |

### GenesisFinalized

```solidity
event GenesisFinalized(uint256 amountValidators)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amountValidators  | uint256 | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

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
error Unauthorized(string message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| message | string | undefined |


