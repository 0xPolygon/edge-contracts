# IRootMintableERC20Predicate









## Methods

### deposit

```solidity
function deposit(contract IERC20Metadata rootToken, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to themselves on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20Metadata | Address of the root token being deposited |
| amount | uint256 | Amount to deposit |

### depositTo

```solidity
function depositTo(contract IERC20Metadata rootToken, address receiver, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to another address on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20Metadata | Address of the root token being deposited |
| receiver | address | undefined |
| amount | uint256 | Amount to deposit |

### mapToken

```solidity
function mapToken(contract IERC20Metadata rootToken) external nonpayable returns (address)
```

Function to be used for token mapping

*Called internally on deposit if token is not mapped already*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC20Metadata | Address of the root token to map |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address Address of the child token |

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



## Events

### L2MintableERC20Deposit

```solidity
event L2MintableERC20Deposit(address indexed rootToken, address indexed childToken, address depositor, address indexed receiver, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor  | address | undefined |
| receiver `indexed` | address | undefined |
| amount  | uint256 | undefined |

### L2MintableERC20Withdraw

```solidity
event L2MintableERC20Withdraw(address indexed rootToken, address indexed childToken, address withdrawer, address indexed receiver, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer  | address | undefined |
| receiver `indexed` | address | undefined |
| amount  | uint256 | undefined |

### L2MintableTokenMapped

```solidity
event L2MintableTokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



