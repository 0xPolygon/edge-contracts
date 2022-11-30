# CVSWithdrawal









## Methods

### ACTIVE_VALIDATOR_SET_SIZE

```solidity
function ACTIVE_VALIDATOR_SET_SIZE() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### MAX_COMMISSION

```solidity
function MAX_COMMISSION() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### MAX_VALIDATOR_SET_SIZE

```solidity
function MAX_VALIDATOR_SET_SIZE() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### NEW_VALIDATOR_SIG

```solidity
function NEW_VALIDATOR_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### REWARD_PRECISION

```solidity
function REWARD_PRECISION() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### WITHDRAWAL_WAIT_PERIOD

```solidity
function WITHDRAWAL_WAIT_PERIOD() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### bls

```solidity
function bls() external view returns (contract IBLS)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IBLS | undefined |

### currentEpochId

```solidity
function currentEpochId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### epochEndBlocks

```solidity
function epochEndBlocks(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### getValidator

```solidity
function getValidator(address validator) external view returns (struct Validator)
```

Gets validator by address.



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | Validator | Validator (BLS public key, self-stake, total stake, commission, withdrawable rewards, activity status) |

### message

```solidity
function message(uint256) external view returns (uint256)
```

Message to sign for registration



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### minDelegation

```solidity
function minDelegation() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### minStake

```solidity
function minStake() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### sprint

```solidity
function sprint() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### whitelist

```solidity
function whitelist(address) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### withdraw

```solidity
function withdraw(address to) external nonpayable
```

Withdraws sender&#39;s withdrawable amount to specified address.



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | Address to withdraw to |

### withdrawable

```solidity
function withdrawable(address account) external view returns (uint256 amount)
```

Calculates how much can be withdrawn for account in this epoch.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to calculate amount for |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Amount withdrawable (in MATIC wei) |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### Withdrawal

```solidity
event Withdrawal(address indexed account, address indexed to, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| to `indexed` | address | undefined |
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



