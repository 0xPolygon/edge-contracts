# ICVSStakingRewards

## Methods

### claimValidatorReward

```solidity
function claimValidatorReward() external nonpayable
```

Claims validator rewards for sender.

### getValidatorReward

```solidity
function getValidatorReward(address validator) external view returns (uint256)
```

Gets validator&#39;s unclaimed rewards.

#### Parameters

| Name      | Type    | Description          |
| --------- | ------- | -------------------- |
| validator | address | Address of validator |

#### Returns

| Name | Type    | Description                                      |
| ---- | ------- | ------------------------------------------------ |
| \_0  | uint256 | Validator&#39;s unclaimed rewards (in MATIC wei) |

## Events

### ValidatorRewardClaimed

```solidity
event ValidatorRewardClaimed(address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |

### ValidatorRewardDistributed

```solidity
event ValidatorRewardDistributed(address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |
