# StakeManager









## Methods

### WITHDRAWAL_WAIT_PERIOD

```solidity
function WITHDRAWAL_WAIT_PERIOD() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### acceptOwnership

```solidity
function acceptOwnership() external nonpayable
```



*The new owner accepts the ownership transfer.*


### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```



*See {IERC20-allowance}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### approve

```solidity
function approve(address spender, uint256 amount) external nonpayable returns (bool)
```



*See {IERC20-approve}. NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on `transferFrom`. This is semantically equivalent to an infinite approval. Requirements: - `spender` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```



*See {IERC20-balanceOf}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfAt

```solidity
function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### decimals

```solidity
function decimals() external view returns (uint8)
```



*Returns the number of decimals used to get its user representation. For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`). Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. This is the default value returned by this function, unless it&#39;s overridden. NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract, including {IERC20-balanceOf} and {IERC20-transfer}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external nonpayable returns (bool)
```



*Atomically decreases the allowance granted to `spender` by the caller. This is an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}. Emits an {Approval} event indicating the updated allowance. Requirements: - `spender` cannot be the zero address. - `spender` must have allowance for the caller of at least `subtractedValue`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| subtractedValue | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### domain

```solidity
function domain() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getValidator

```solidity
function getValidator(address validator_) external view returns (struct Validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator_ | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | Validator | undefined |

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) external nonpayable returns (bool)
```



*Atomically increases the allowance granted to `spender` by the caller. This is an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}. Emits an {Approval} event indicating the updated allowance. Requirements: - `spender` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| addedValue | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### initialize

```solidity
function initialize(address newStakingToken, address newBls, address epochManager, string newDomain, GenesisValidator[] genesisValidators) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newStakingToken | address | undefined |
| newBls | address | undefined |
| epochManager | address | undefined |
| newDomain | string | undefined |
| genesisValidators | GenesisValidator[] | undefined |

### name

```solidity
function name() external view returns (string)
```



*Returns the name of the token.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

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

### register

```solidity
function register(uint256[2] signature, uint256[4] pubkey) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | undefined |
| pubkey | uint256[4] | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### stake

```solidity
function stake(uint256 amount) external nonpayable
```

called by a validator to stake for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### stakeOf

```solidity
function stakeOf(address validator) external view returns (uint256 amount)
```

returns the amount staked by a validator for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### symbol

```solidity
function symbol() external view returns (string)
```



*Returns the symbol of the token, usually a shorter version of the name.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### totalStake

```solidity
function totalStake() external view returns (uint256 amount)
```

returns the total amount staked for all child chains




#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```



*See {IERC20-totalSupply}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalSupplyAt

```solidity
function totalSupplyAt(uint256 epochNumber) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transfer

```solidity
function transfer(address to, uint256 amount) external nonpayable returns (bool)
```



*See {IERC20-transfer}. Requirements: - `to` cannot be the zero address. - the caller must have a balance of at least `amount`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external nonpayable returns (bool)
```



*See {IERC20-transferFrom}. Emits an {Approval} event indicating the updated allowance. This is not required by the EIP. See the note at the beginning of {ERC20}. NOTE: Does not update the allowance if the current allowance is the maximum `uint256`. Requirements: - `from` and `to` cannot be the zero address. - `from` must have a balance of at least `amount`. - the caller must have allowance for ``from``&#39;s tokens of at least `amount`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### unstake

```solidity
function unstake(uint256 amount) external nonpayable
```

called by a validator to unstake



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### validators

```solidity
function validators(address) external view returns (address addr, bool isWhitelisted, bool isActive)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |
| isWhitelisted | bool | undefined |
| isActive | bool | undefined |

### whitelistValidators

```solidity
function whitelistValidators(address[] validators_) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validators_ | address[] | undefined |

### withdraw

```solidity
function withdraw() external nonpayable
```

allows a validator to complete a withdrawal

*calls the bridge to release the funds on root*


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

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value)
```



*Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| spender `indexed` | address | undefined |
| value  | uint256 | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

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

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### Snapshot

```solidity
event Snapshot(uint256 id)
```



*Emitted by {_snapshot} when a snapshot identified by `id` is created.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| id  | uint256 | undefined |

### StakeAdded

```solidity
event StakeAdded(address indexed validator, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| amount  | uint256 | undefined |

### StakeRemoved

```solidity
event StakeRemoved(address indexed validator, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| amount  | uint256 | undefined |

### StakeWithdrawn

```solidity
event StakeWithdrawn(address indexed account, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| amount  | uint256 | undefined |

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value)
```



*Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| value  | uint256 | undefined |

### ValidatorDeactivated

```solidity
event ValidatorDeactivated(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### ValidatorRegistered

```solidity
event ValidatorRegistered(address indexed validator, uint256[4] blsKey)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| blsKey  | uint256[4] | undefined |



## Errors

### InvalidSignature

```solidity
error InvalidSignature(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

### Unauthorized

```solidity
error Unauthorized(string message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| message | string | undefined |


