# EpochManager









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
function epochEndingBlocks(uint256) external view returns (uint256)
```

returns the epoch ending block of given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### epochs

```solidity
function epochs(uint256) external view returns (uint256 startBlock, uint256 endBlock, bytes32 epochRoot)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| startBlock | uint256 | undefined |
| endBlock | uint256 | undefined |
| epochRoot | bytes32 | undefined |

### initialize

```solidity
function initialize(address newStakeManager, address newRewardToken, address newRewardWallet, address newNetworkParams) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newStakeManager | address | undefined |
| newRewardToken | address | undefined |
| newRewardWallet | address | undefined |
| newNetworkParams | address | undefined |

### networkParams

```solidity
function networkParams() external view returns (contract NetworkParams)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract NetworkParams | undefined |

### paidRewardPerEpoch

```solidity
function paidRewardPerEpoch(uint256) external view returns (uint256)
```

returns the total reward paid for the given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### pendingRewards

```solidity
function pendingRewards(address) external view returns (uint256)
```

returns the pending reward for the given account



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### rewardToken

```solidity
function rewardToken() external view returns (contract IERC20Upgradeable)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IERC20Upgradeable | undefined |

### rewardWallet

```solidity
function rewardWallet() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stakeManager

```solidity
function stakeManager() external view returns (contract ERC20SnapshotUpgradeable)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ERC20SnapshotUpgradeable | undefined |

### withdrawReward

```solidity
function withdrawReward() external nonpayable
```

withdraws pending rewards for the sender (validator)






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



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


