# NetworkParams

*Polygon Technology (@QEDK)*

> NetworkParams

Configurable network parameters that are read by the client on each epoch

*The contract allows for configurable network parameters without the need for a hardfork*

## Methods

### acceptOwnership

```solidity
function acceptOwnership() external nonpayable
```



*The new owner accepts the ownership transfer.*


### baseFeeChangeDenom

```solidity
function baseFeeChangeDenom() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### blockTime

```solidity
function blockTime() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### blockTimeDrift

```solidity
function blockTimeDrift() external view returns (uint256)
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

### epochReward

```solidity
function epochReward() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### epochSize

```solidity
function epochSize() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initialize

```solidity
function initialize(InitParams initParams) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| initParams | InitParams | undefined |

### maxValidatorSetSize

```solidity
function maxValidatorSetSize() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### minValidatorSetSize

```solidity
function minValidatorSetSize() external view returns (uint256)
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

### pendingOwner

```solidity
function pendingOwner() external view returns (address)
```



*Returns the address of the pending owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### proposalThreshold

```solidity
function proposalThreshold() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### setNewBaseFeeChangeDenom

```solidity
function setNewBaseFeeChangeDenom(uint256 newBaseFeeChangeDenom) external nonpayable
```

function to set new base fee change denominator

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newBaseFeeChangeDenom | uint256 | new base fee change denominator |

### setNewBlockTime

```solidity
function setNewBlockTime(uint256 newBlockTime) external nonpayable
```

function to set new block time

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newBlockTime | uint256 | new block time |

### setNewBlockTimeDrift

```solidity
function setNewBlockTimeDrift(uint256 newBlockTimeDrift) external nonpayable
```

function to set new block time drift

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newBlockTimeDrift | uint256 | new block time drift |

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

### setNewEpochReward

```solidity
function setNewEpochReward(uint256 newEpochReward) external nonpayable
```

function to set new epoch reward

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newEpochReward | uint256 | new epoch reward |

### setNewEpochSize

```solidity
function setNewEpochSize(uint256 newEpochSize) external nonpayable
```

function to set new epoch size

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newEpochSize | uint256 | new epoch reward |

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

### setNewMinValidatorSetSize

```solidity
function setNewMinValidatorSetSize(uint256 newMinValidatorSetSize) external nonpayable
```

function to set new minimum validator set size

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newMinValidatorSetSize | uint256 | new minimum validator set size |

### setNewProposalThreshold

```solidity
function setNewProposalThreshold(uint256 newProposalThreshold) external nonpayable
```

function to set new proposal threshold

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newProposalThreshold | uint256 | new proposal threshold |

### setNewSprintSize

```solidity
function setNewSprintSize(uint256 newSprintSize) external nonpayable
```

function to set new sprint size

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newSprintSize | uint256 | new sprint size |

### setNewVotingDelay

```solidity
function setNewVotingDelay(uint256 newVotingDelay) external nonpayable
```

function to set new voting delay

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newVotingDelay | uint256 | new voting delay |

### setNewVotingPeriod

```solidity
function setNewVotingPeriod(uint256 newVotingPeriod) external nonpayable
```

function to set new voting period

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newVotingPeriod | uint256 | new voting period |

### setNewWithdrawalWaitPeriod

```solidity
function setNewWithdrawalWaitPeriod(uint256 newWithdrawalWaitPeriod) external nonpayable
```

function to set new withdrawal wait period

*disallows setting of a zero value for sanity check purposes*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newWithdrawalWaitPeriod | uint256 | new withdrawal wait period |

### sprintSize

```solidity
function sprintSize() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### votingDelay

```solidity
function votingDelay() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### votingPeriod

```solidity
function votingPeriod() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdrawalWaitPeriod

```solidity
function withdrawalWaitPeriod() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



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

### NewBaseFeeChangeDenom

```solidity
event NewBaseFeeChangeDenom(uint256 indexed baseFeeChangeDenom)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| baseFeeChangeDenom `indexed` | uint256 | undefined |

### NewBlockTime

```solidity
event NewBlockTime(uint256 indexed blockTime)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| blockTime `indexed` | uint256 | undefined |

### NewBlockTimeDrift

```solidity
event NewBlockTimeDrift(uint256 indexed blockTimeDrift)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| blockTimeDrift `indexed` | uint256 | undefined |

### NewCheckpointBlockInterval

```solidity
event NewCheckpointBlockInterval(uint256 indexed checkpointInterval)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| checkpointInterval `indexed` | uint256 | undefined |

### NewEpochReward

```solidity
event NewEpochReward(uint256 indexed reward)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| reward `indexed` | uint256 | undefined |

### NewEpochSize

```solidity
event NewEpochSize(uint256 indexed size)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| size `indexed` | uint256 | undefined |

### NewMaxValidatorSetSize

```solidity
event NewMaxValidatorSetSize(uint256 indexed maxValidatorSet)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| maxValidatorSet `indexed` | uint256 | undefined |

### NewMinValidatorSetSize

```solidity
event NewMinValidatorSetSize(uint256 indexed minValidatorSet)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| minValidatorSet `indexed` | uint256 | undefined |

### NewProposalThreshold

```solidity
event NewProposalThreshold(uint256 indexed proposalThreshold)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalThreshold `indexed` | uint256 | undefined |

### NewSprintSize

```solidity
event NewSprintSize(uint256 indexed size)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| size `indexed` | uint256 | undefined |

### NewVotingDelay

```solidity
event NewVotingDelay(uint256 indexed votingDelay)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| votingDelay `indexed` | uint256 | undefined |

### NewVotingPeriod

```solidity
event NewVotingPeriod(uint256 indexed votingPeriod)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| votingPeriod `indexed` | uint256 | undefined |

### NewWithdrawalWaitPeriod

```solidity
event NewWithdrawalWaitPeriod(uint256 indexed withdrawalPeriod)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawalPeriod `indexed` | uint256 | undefined |

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



