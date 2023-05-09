# ChildERC20

*Polygon Technology (@QEDK)*

> ChildERC20

Child token template for ChildERC20 predicate deployments

*All child tokens are clones of this contract. Burning and minting is controlled by respective predicates only.*

## Methods

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

### burn

```solidity
function burn(address account, uint256 amount) external nonpayable returns (bool)
```

Burns an amount of tokens from a particular address

*Can only be called by the predicate address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | Account of the user to burn the tokens from |
| amount | uint256 | Amount of tokens to burn from the account |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is succesful |

### decimals

```solidity
function decimals() external view returns (uint8)
```

Returns the decimals places of the token




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | uint8 Returns the decimals places of the token. |

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

### executeMetaTransaction

```solidity
function executeMetaTransaction(address userAddress, bytes functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) external nonpayable returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |
| functionSignature | bytes | undefined |
| sigR | bytes32 | undefined |
| sigS | bytes32 | undefined |
| sigV | uint8 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getNonce

```solidity
function getNonce(address user) external view returns (uint256 nonce)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| nonce | uint256 | undefined |

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
function initialize(address rootToken_, string name_, string symbol_, uint8 decimals_) external nonpayable
```



*Sets the values for {rootToken}, {name}, {symbol} and {decimals}. All these values are immutable: they can only be set once during initialization.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken_ | address | undefined |
| name_ | string | undefined |
| symbol_ | string | undefined |
| decimals_ | uint8 | undefined |

### invalidateNext

```solidity
function invalidateNext(uint256 offset) external nonpayable
```



*Invalidates next &quot;offset&quot; number of nonces for the calling address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| offset | uint256 | undefined |

### mint

```solidity
function mint(address account, uint256 amount) external nonpayable returns (bool)
```

Mints an amount of tokens to a particular address

*Can only be called by the predicate address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | Account of the user to mint the tokens to |
| amount | uint256 | Amount of tokens to mint to the account |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is succesful |

### name

```solidity
function name() external view returns (string)
```



*Returns the name of the token.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### predicate

```solidity
function predicate() external view returns (address)
```

Returns predicate address controlling the child token




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address Returns the address of the predicate |

### rootToken

```solidity
function rootToken() external view returns (address)
```

Returns predicate address controlling the child token




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address Returns the address of the predicate |

### symbol

```solidity
function symbol() external view returns (string)
```



*Returns the symbol of the token, usually a shorter version of the name.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```



*See {IERC20-totalSupply}.*


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



## Events

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

### MetaTransactionExecuted

```solidity
event MetaTransactionExecuted(address userAddress, address relayerAddress, bytes functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress  | address | undefined |
| relayerAddress  | address | undefined |
| functionSignature  | bytes | undefined |

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



