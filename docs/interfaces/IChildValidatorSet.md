# IChildValidatorSet

_Polygon Technology_

> ChildValidatorSet

Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.

_The contract is used to complete validator registration and store self-stake and delegated MATIC amounts. It manages staking, epoch committing, and reward distribution._

## Methods

### claimDelegatorReward

```solidity
function claimDelegatorReward(address validator, bool restake) external nonpayable
```

Claims delegator rewards for sender.

#### Parameters

| Name      | Type    | Description                               |
| --------- | ------- | ----------------------------------------- |
| validator | address | Validator to claim from                   |
| restake   | bool    | Whether to redelegate the claimed rewards |

### commitEpoch

```solidity
function commitEpoch(uint256 id, Epoch epoch, Uptime uptime) external nonpayable
```

#### Parameters

| Name   | Type    | Description |
| ------ | ------- | ----------- |
| id     | uint256 | undefined   |
| epoch  | Epoch   | undefined   |
| uptime | Uptime  | undefined   |

### delegate

```solidity
function delegate(address validator, bool restake) external payable
```

Delegates sent amount to validator. Claims rewards beforehand.

#### Parameters

| Name      | Type    | Description                               |
| --------- | ------- | ----------------------------------------- |
| validator | address | Validator to delegate to                  |
| restake   | bool    | Whether to redelegate the claimed rewards |

### delegationOf

```solidity
function delegationOf(address validator, address delegator) external view returns (uint256)
```

Gets amount delegated by delegator to validator.

#### Parameters

| Name      | Type    | Description          |
| --------- | ------- | -------------------- |
| validator | address | Address of validator |
| delegator | address | Address of delegator |

#### Returns

| Name | Type    | Description                     |
| ---- | ------- | ------------------------------- |
| \_0  | uint256 | Amount delegated (in MATIC wei) |

### getCurrentValidatorSet

```solidity
function getCurrentValidatorSet() external view returns (address[])
```

Gets addresses of active validators in this epoch, sorted by total stake (self-stake + delegation)

#### Returns

| Name | Type      | Description                                                                  |
| ---- | --------- | ---------------------------------------------------------------------------- |
| \_0  | address[] | Array of addresses of active validators in this epoch, sorted by total stake |

### getDelegatorReward

```solidity
function getDelegatorReward(address validator, address delegator) external view returns (uint256)
```

Gets delegators&#39;s unclaimed rewards with validator.

#### Parameters

| Name      | Type    | Description          |
| --------- | ------- | -------------------- |
| validator | address | Address of validator |
| delegator | address | Address of delegator |

#### Returns

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| \_0  | uint256 | Delegator&#39;s unclaimed rewards with validator (in MATIC wei) |

### getEpochByBlock

```solidity
function getEpochByBlock(uint256 blockNumber) external view returns (struct Epoch)
```

Look up an epoch by block number. Searches in O(log n) time.

#### Parameters

| Name        | Type    | Description                 |
| ----------- | ------- | --------------------------- |
| blockNumber | uint256 | ID of epoch to be committed |

#### Returns

| Name | Type  | Description                                           |
| ---- | ----- | ----------------------------------------------------- |
| \_0  | Epoch | Epoch Returns epoch if found, or else, the last epoch |

### totalActiveStake

```solidity
function totalActiveStake() external view returns (uint256)
```

Calculates total stake of active validators (self-stake + delegation).

#### Returns

| Name | Type    | Description                                     |
| ---- | ------- | ----------------------------------------------- |
| \_0  | uint256 | Total stake of active validators (in MATIC wei) |

### undelegate

```solidity
function undelegate(address validator, uint256 amount) external nonpayable
```

Undelegates amount from validator for sender. Claims rewards beforehand.

#### Parameters

| Name      | Type    | Description                  |
| --------- | ------- | ---------------------------- |
| validator | address | Validator to undelegate from |
| amount    | uint256 | The amount to undelegate     |

## Events

### Delegated

```solidity
event Delegated(address indexed delegator, address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| delegator `indexed` | address | undefined   |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |

### DelegatorRewardClaimed

```solidity
event DelegatorRewardClaimed(address indexed delegator, address indexed validator, bool indexed restake, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| delegator `indexed` | address | undefined   |
| validator `indexed` | address | undefined   |
| restake `indexed`   | bool    | undefined   |
| amount              | uint256 | undefined   |

### DelegatorRewardDistributed

```solidity
event DelegatorRewardDistributed(address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |

### NewEpoch

```solidity
event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot)
```

#### Parameters

| Name                 | Type    | Description |
| -------------------- | ------- | ----------- |
| id `indexed`         | uint256 | undefined   |
| startBlock `indexed` | uint256 | undefined   |
| endBlock `indexed`   | uint256 | undefined   |
| epochRoot            | bytes32 | undefined   |

### Undelegated

```solidity
event Undelegated(address indexed delegator, address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| delegator `indexed` | address | undefined   |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |
