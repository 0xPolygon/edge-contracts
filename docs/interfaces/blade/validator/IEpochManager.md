# IEpochManager



> IEpochManager

Tracks epochs and distributes rewards to validators for committed epochs



## Methods

### commitEpoch

```solidity
function commitEpoch(uint256 id, uint256 epochSize, Epoch epoch) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| epochSize | uint256 | undefined |
| epoch | Epoch | undefined |

### currentEpochId

```solidity
function currentEpochId() external view returns (uint256)
```

returns currentEpochId




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### distributeRewardFor

```solidity
function distributeRewardFor(uint256 epochId, uint256 epochSize, Uptime[] uptime) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |
| epochSize | uint256 | undefined |
| uptime | Uptime[] | undefined |

### epochEndingBlocks

```solidity
function epochEndingBlocks(uint256 epochId) external view returns (uint256)
```

returns the epoch ending block of given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### paidRewardPerEpoch

```solidity
function paidRewardPerEpoch(uint256 epochId) external view returns (uint256)
```

returns the total reward paid for the given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### pendingRewards

```solidity
function pendingRewards(address account) external view returns (uint256)
```

returns the pending reward for the given account



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdrawReward

```solidity
function withdrawReward() external nonpayable
```

withdraws pending rewards for the sender (validator)






## Events

### NewEpoch

```solidity
event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| startBlock `indexed` | uint256 | undefined |
| endBlock `indexed` | uint256 | undefined |
| epochRoot  | bytes32 | undefined |

### RewardDistributed

```solidity
event RewardDistributed(uint256 indexed epochId, uint256 totalReward)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId `indexed` | uint256 | undefined |
| totalReward  | uint256 | undefined |



