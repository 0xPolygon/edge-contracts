# IBladeManager



> IBladeManager

Manages genesis of a blade chan when bridge is enabled



## Methods

### addGenesisBalance

```solidity
function addGenesisBalance(uint256 nonStakeAmount, uint256 stakeAmount) external nonpayable
```

addGenesisBalance is used to specGenesisAccountnce information for genesis accounts on a  Blade chain. It is applicable only in case Blade native contract is mapped to a pre-existing rootchain ERC20 token.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nonStakeAmount | uint256 | represents the amount to be premined in the genesis which is not staked. |
| stakeAmount | uint256 | represents the amount to be premined in genesis which is going to be staked. |

### finalizeGenesis

```solidity
function finalizeGenesis() external nonpayable
```

GenesisAccounts initial genesis validator set

*only callable by owner*


### genesisSet

```solidity
function genesisSet() external view returns (struct GenesisAccount[])
```

returns the genesis validator set with their balances




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | GenesisAccount[] | undefined |

### initialize

```solidity
function initialize(address newRootERC20Predicate, GenesisAccount[] genesisValidators) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRootERC20Predicate | address | undefined |
| genesisValidators | GenesisAccount[] | undefined |



## Events

### GenesisBalanceAdded

```solidity
event GenesisBalanceAdded(address indexed account, uint256 indexed amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| amount `indexed` | uint256 | undefined |

### GenesisFinalized

```solidity
event GenesisFinalized(uint256 amountValidators)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amountValidators  | uint256 | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| message | string | undefined |


