# ForkParams

*Polygon Technology (@QEDK)*

> ForkParams

Configurable softfork features that are read by the client on each epoch

*The contract allows for configurable softfork parameters without genesis updation*

## Methods

### addNewFeature

```solidity
function addNewFeature(uint256 blockNumber, string feature) external nonpayable
```

function to add a new feature at a block number

*block number must be set in the future and feature must already not be scheduled*

#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | block number to schedule the feature |
| feature | string | feature name to schedule |

### featureToBlockNumber

```solidity
function featureToBlockNumber(bytes32) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### isFeatureActivated

```solidity
function isFeatureActivated(string feature) external view returns (bool)
```

function to check if a feature is activated

*returns true if feature is activated, false if feature is scheduled in the future and reverts if feature does not exists*

#### Parameters

| Name | Type | Description |
|---|---|---|
| feature | string | feature name to check for activation |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

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


### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### updateFeatureBlock

```solidity
function updateFeatureBlock(uint256 newBlockNumber, string feature) external nonpayable
```

function to update the block number for a feature

*block number must be set in the future and feature must already be scheduled*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newBlockNumber | uint256 | new block number to schedule the feature at |
| feature | string | feature name to schedule |



## Events

### NewFeature

```solidity
event NewFeature(bytes32 indexed feature, uint256 indexed block)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| feature `indexed` | bytes32 | undefined |
| block `indexed` | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### UpdatedFeature

```solidity
event UpdatedFeature(bytes32 indexed feature, uint256 indexed block)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| feature `indexed` | bytes32 | undefined |
| block `indexed` | uint256 | undefined |



