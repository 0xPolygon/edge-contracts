# NetworkParams

*Polygon Technology (@QEDK)*

> NetworkParams

Configurable network parameters that are read by the client on each epoch

*The contract allows for configurable network parameters without the need for a hardfork*

## Methods

### blockGasLimit

```solidity
function blockGasLimit() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### checkpointBlockInterval

```solidity
function checkpointBlockInterval() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### maxValidatorSetSize

```solidity
function maxValidatorSetSize() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### minStake

```solidity
function minStake() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### setNewBlockGasLimit

```solidity
function setNewBlockGasLimit(uint256 newBlockGasLimit) external nonpayable
```

function to set new block gas limit

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newBlockGasLimit | uint256 | new block gas limit |

### setNewCheckpointBlockInterval

```solidity
function setNewCheckpointBlockInterval(uint256 newCheckpointBlockInterval) external nonpayable
```

function to set new checkpoint block interval

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newCheckpointBlockInterval | uint256 | new checkpoint block interval |

### setNewMaxValidatorSetSize

```solidity
function setNewMaxValidatorSetSize(uint256 newMaxValidatorSetSize) external nonpayable
```

function to set new maximum validator set size

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newMaxValidatorSetSize | uint256 | new maximum validator set size |

### setNewMinStake

```solidity
function setNewMinStake(uint256 newMinStake) external nonpayable
```

function to set new minimum stake

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newMinStake | uint256 | new minimum stake |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### NewBlockGasLimit

```solidity
event NewBlockGasLimit(uint256 indexed value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value `indexed` | uint256 | undefined |

### NewCheckpointBlockInterval

```solidity
event NewCheckpointBlockInterval(uint256 indexed value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value `indexed` | uint256 | undefined |

### NewMaxValdidatorSetSize

```solidity
event NewMaxValdidatorSetSize(uint256 indexed value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value `indexed` | uint256 | undefined |

### NewMinStake

```solidity
event NewMinStake(uint256 indexed value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value `indexed` | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



