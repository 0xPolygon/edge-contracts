# RewardPool









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

### baseReward

```solidity
function baseReward() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### distributeRewardFor

```solidity
function distributeRewardFor(uint256 epochId, Uptime[] uptime) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |
| uptime | Uptime[] | undefined |

### initialize

```solidity
function initialize(address newRewardToken, address newRewardWallet, address newValidatorSet, uint256 newBaseReward) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRewardToken | address | undefined |
| newRewardWallet | address | undefined |
| newValidatorSet | address | undefined |
| newBaseReward | uint256 | undefined |

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

### validatorSet

```solidity
function validatorSet() external view returns (contract IValidatorSet)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IValidatorSet | undefined |

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


