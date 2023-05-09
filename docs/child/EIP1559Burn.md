# EIP1559Burn

*Polygon Technology (@QEDK)*

> EIP1559Burn

Burns the native token on root chain as an ERC20



## Methods

### burnDestination

```solidity
function burnDestination() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### childERC20Predicate

```solidity
function childERC20Predicate() external view returns (contract IChildERC20Predicate)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IChildERC20Predicate | undefined |

### initialize

```solidity
function initialize(contract IChildERC20Predicate newChildERC20Predicate, address newBurnDestination) external nonpayable
```

Initilization function for EIP1559 burn contract

*Can only be called once*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newChildERC20Predicate | contract IChildERC20Predicate | Address of the ERC20 predicate on child chain |
| newBurnDestination | address | Address on the root chain to burn the tokens and send to |

### withdraw

```solidity
function withdraw() external nonpayable
```

Function to burn native tokens on child chain and send them to burn destination on root

*Takes the entire current native token balance and burns it*




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

### NativeTokenBurnt

```solidity
event NativeTokenBurnt(address indexed burner, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| burner `indexed` | address | undefined |
| amount  | uint256 | undefined |



