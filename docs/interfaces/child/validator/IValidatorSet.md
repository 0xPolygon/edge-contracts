# IValidatorSet

*Polygon Technology (@gretzke)*

> IValidatorSet

Manages voting power for validators and commits epochs for child chains

*Voting power is synced between the stake manager on root on stake and unstake actions*

## Methods

### EPOCH_SIZE

```solidity
function EPOCH_SIZE() external view returns (uint256)
```

amount of blocks in an epoch

*when an epoch is committed a multiple of this number of blocks must be committed*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfAt

```solidity
function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256)
```

returns a validator balance for a given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### commitEpoch

```solidity
function commitEpoch(uint256 id, Epoch epoch) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| epoch | Epoch | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256 counter, address sender, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

### pendingWithdrawals

```solidity
function pendingWithdrawals(address account) external view returns (uint256)
```

Calculates how much is yet to become withdrawable for account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to calculate amount for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Amount not yet withdrawable (in MATIC wei) |

### totalBlocks

```solidity
function totalBlocks(uint256 epochId) external view returns (uint256 length)
```

total amount of blocks in a given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| length | uint256 | undefined |

### totalSupplyAt

```solidity
function totalSupplyAt(uint256 epochNumber) external view returns (uint256)
```

returns the total supply for a given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### unstake

```solidity
function unstake(uint256 amount) external nonpayable
```

allows a validator to announce their intention to withdraw a given amount of tokens

*initializes a waiting period before the tokens can be withdrawn*

#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### withdraw

```solidity
function withdraw() external nonpayable
```

allows a validator to complete a withdrawal

*calls the bridge to release the funds on root*


### withdrawable

```solidity
function withdrawable(address account) external view returns (uint256)
```

Calculates how much can be withdrawn for account in this epoch.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to calculate amount for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Amount withdrawable (in MATIC wei) |



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

### Slashed

```solidity
event Slashed(uint256 indexed validator, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | uint256 | undefined |
| amount  | uint256 | undefined |

### Withdrawal

```solidity
event Withdrawal(address indexed account, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| amount  | uint256 | undefined |

### WithdrawalRegistered

```solidity
event WithdrawalRegistered(address indexed account, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| amount  | uint256 | undefined |



