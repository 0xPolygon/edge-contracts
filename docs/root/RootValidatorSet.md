# RootValidatorSet

*Polygon Technology*

> RootValidatorSet

Validator set contract for Polygon PoS v3. This contract serves the purpose of validator registration.

*The contract is used to onboard new validators and register their ECDSA and BLS public keys.*

## Methods

### ACTIVE_VALIDATOR_SET_SIZE

```solidity
function ACTIVE_VALIDATOR_SET_SIZE() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### activeValidatorSetSize

```solidity
function activeValidatorSetSize() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addValidators

```solidity
function addValidators(RootValidatorSet.Validator[] newValidators) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newValidators | RootValidatorSet.Validator[] | undefined |

### checkpointManager

```solidity
function checkpointManager() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### currentValidatorId

```solidity
function currentValidatorId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getValidator

```solidity
function getValidator(uint256 id) external view returns (struct RootValidatorSet.Validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | RootValidatorSet.Validator | undefined |

### getValidatorBlsKey

```solidity
function getValidatorBlsKey(uint256 id) external view returns (uint256[4])
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[4] | undefined |

### initialize

```solidity
function initialize(address governance, address newCheckpointManager, address[] validatorAddresses, uint256[4][] validatorPubkeys) external nonpayable
```

Initialization function for RootValidatorSet

*Contract can only be initialized once, also transfers ownership to initializing address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| governance | address | undefined |
| newCheckpointManager | address | undefined |
| validatorAddresses | address[] | Array of validator pubkeys to seed the contract with. |
| validatorPubkeys | uint256[4][] | undefined |

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

### validatorIdByAddress

```solidity
function validatorIdByAddress(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### validators

```solidity
function validators(uint256) external view returns (address _address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _address | address | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### NewValidator

```solidity
event NewValidator(uint256 indexed id, address indexed validator, uint256[4] blsKey)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| validator `indexed` | address | undefined |
| blsKey  | uint256[4] | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



