# IChildValidatorSet

_Polygon Technology_

> ChildValidatorSet

Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.

_The contract is used to complete validator registration and store self-stake and delegated MATIC amounts. It manages staking, epoch committing, and reward distribution._

## Methods

### addToWhitelist

```solidity
function addToWhitelist(address[] whitelistAddreses) external nonpayable
```

Adds addresses that are allowed to register as validators.

#### Parameters

| Name              | Type      | Description                   |
| ----------------- | --------- | ----------------------------- |
| whitelistAddreses | address[] | Array of address to whitelist |

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

### claimValidatorReward

```solidity
function claimValidatorReward() external nonpayable
```

Claims validator rewards for sender.

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

### commitEpoch

```solidity
function commitEpoch(uint256 curEpochId, Epoch epoch, Uptime uptime, uint256 blockNumber, uint256 pbftRound, uint256 epochId, DoubleSignerSlashingInput[] inputs) external nonpayable
```

#### Parameters

| Name        | Type                        | Description |
| ----------- | --------------------------- | ----------- |
| curEpochId  | uint256                     | undefined   |
| epoch       | Epoch                       | undefined   |
| uptime      | Uptime                      | undefined   |
| blockNumber | uint256                     | undefined   |
| pbftRound   | uint256                     | undefined   |
| epochId     | uint256                     | undefined   |
| inputs      | DoubleSignerSlashingInput[] | undefined   |

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

### getValidator

```solidity
function getValidator(address validator) external view returns (struct Validator)
```

Gets validator by address.

#### Parameters

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| validator | address | undefined   |

#### Returns

| Name | Type      | Description                                                                                            |
| ---- | --------- | ------------------------------------------------------------------------------------------------------ |
| \_0  | Validator | Validator (BLS public key, self-stake, total stake, commission, withdrawable rewards, activity status) |

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

### pendingWithdrawals

```solidity
function pendingWithdrawals(address account) external view returns (uint256)
```

Calculates how much is yet to become withdrawable for account.

#### Parameters

| Name    | Type    | Description                         |
| ------- | ------- | ----------------------------------- |
| account | address | The account to calculate amount for |

#### Returns

| Name | Type    | Description                                |
| ---- | ------- | ------------------------------------------ |
| \_0  | uint256 | Amount not yet withdrawable (in MATIC wei) |

### register

```solidity
function register(uint256[2] signature, uint256[4] pubkey) external nonpayable
```

Validates BLS signature with the provided pubkey and registers validators into the set.

#### Parameters

| Name      | Type       | Description                           |
| --------- | ---------- | ------------------------------------- |
| signature | uint256[2] | Signature to validate message against |
| pubkey    | uint256[4] | BLS public key of validator           |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address[] whitelistAddreses) external nonpayable
```

Deletes addresses that are allowed to register as validators.

#### Parameters

| Name              | Type      | Description                               |
| ----------------- | --------- | ----------------------------------------- |
| whitelistAddreses | address[] | Array of address to remove from whitelist |

### setCommission

```solidity
function setCommission(uint256 newCommission) external nonpayable
```

Sets commission for validator.

#### Parameters

| Name          | Type    | Description                 |
| ------------- | ------- | --------------------------- |
| newCommission | uint256 | New commission (100 = 100%) |

### sortedValidators

```solidity
function sortedValidators(uint256 n) external view returns (address[])
```

Gets first n active validators sorted by total stake.

#### Parameters

| Name | Type    | Description                            |
| ---- | ------- | -------------------------------------- |
| n    | uint256 | Desired number of validators to return |

#### Returns

| Name | Type      | Description                                                                                                                       |
| ---- | --------- | --------------------------------------------------------------------------------------------------------------------------------- |
| \_0  | address[] | Returns array of addresses of first n active validators sorted by total stake, or fewer if there are not enough active validators |

### stake

```solidity
function stake() external payable
```

Stakes sent amount. Claims rewards beforehand.

### totalActiveStake

```solidity
function totalActiveStake() external view returns (uint256)
```

Calculates total stake of active validators (self-stake + delegation).

#### Returns

| Name | Type    | Description                                     |
| ---- | ------- | ----------------------------------------------- |
| \_0  | uint256 | Total stake of active validators (in MATIC wei) |

### totalStake

```solidity
function totalStake() external view returns (uint256)
```

Calculates total stake in the network (self-stake + delegation).

#### Returns

| Name | Type    | Description                |
| ---- | ------- | -------------------------- |
| \_0  | uint256 | Total stake (in MATIC wei) |

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

### unstake

```solidity
function unstake(uint256 amount) external nonpayable
```

Unstakes amount for sender. Claims rewards beforehand.

#### Parameters

| Name   | Type    | Description       |
| ------ | ------- | ----------------- |
| amount | uint256 | Amount to unstake |

### withdraw

```solidity
function withdraw(address to) external nonpayable
```

Withdraws sender&#39;s withdrawable amount to specified address.

#### Parameters

| Name | Type    | Description            |
| ---- | ------- | ---------------------- |
| to   | address | Address to withdraw to |

### withdrawable

```solidity
function withdrawable(address account) external view returns (uint256)
```

Calculates how much can be withdrawn for account in this epoch.

#### Parameters

| Name    | Type    | Description                         |
| ------- | ------- | ----------------------------------- |
| account | address | The account to calculate amount for |

#### Returns

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| \_0  | uint256 | Amount withdrawable (in MATIC wei) |

## Events

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |

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

### DoubleSignerSlashed

```solidity
event DoubleSignerSlashed(address indexed validator, uint256 indexed epoch, uint256 indexed round)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |
| epoch `indexed`     | uint256 | undefined   |
| round `indexed`     | uint256 | undefined   |

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

### NewValidator

```solidity
event NewValidator(address indexed validator, uint256[4] blsKey)
```

#### Parameters

| Name                | Type       | Description |
| ------------------- | ---------- | ----------- |
| validator `indexed` | address    | undefined   |
| blsKey              | uint256[4] | undefined   |

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |

### Staked

```solidity
event Staked(address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |

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

### Unstaked

```solidity
event Unstaked(address indexed validator, uint256 amount)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |
| amount              | uint256 | undefined   |

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

### Withdrawal

```solidity
event Withdrawal(address indexed account, address indexed to, uint256 amount)
```

#### Parameters

| Name              | Type    | Description |
| ----------------- | ------- | ----------- |
| account `indexed` | address | undefined   |
| to `indexed`      | address | undefined   |
| amount            | uint256 | undefined   |

### WithdrawalRegistered

```solidity
event WithdrawalRegistered(address indexed account, uint256 amount)
```

#### Parameters

| Name              | Type    | Description |
| ----------------- | ------- | ----------- |
| account `indexed` | address | undefined   |
| amount            | uint256 | undefined   |

## Errors

### Invalid

```solidity
error Invalid(string src, string msg)
```

#### Parameters

| Name | Type   | Description |
| ---- | ------ | ----------- |
| src  | string | undefined   |
| msg  | string | undefined   |

### StakeRequirement

```solidity
error StakeRequirement(string src, string msg)
```

#### Parameters

| Name | Type   | Description |
| ---- | ------ | ----------- |
| src  | string | undefined   |
| msg  | string | undefined   |
