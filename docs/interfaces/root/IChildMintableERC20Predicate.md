# IChildMintableERC20Predicate









## Methods

### initialize

```solidity
function initialize(address newL2StateSender, address newStateReceiver, address newRootERC20Predicate, address newChildTokenTemplate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newL2StateSender | address | undefined |
| newStateReceiver | address | undefined |
| newRootERC20Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |

### onL2StateReceive

```solidity
function onL2StateReceive(uint256 id, address sender, bytes data) external nonpayable
```

Called by exit helper when state is received from L2



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| sender | address | Address of the sender on the child chain |
| data | bytes | Data sent by the sender |

### withdraw

```solidity
function withdraw(contract IChildERC20 childToken, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | undefined |
| amount | uint256 | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC20 childToken, address receiver, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | undefined |
| receiver | address | undefined |
| amount | uint256 | undefined |



## Events

### MintableERC20Deposit

```solidity
event MintableERC20Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| amount  | uint256 | undefined |

### MintableERC20Withdraw

```solidity
event MintableERC20Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| amount  | uint256 | undefined |

### MintableTokenMapped

```solidity
event MintableTokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



