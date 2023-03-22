# ICustomSupernetManager









## Methods

### onL2StateReceive

```solidity
function onL2StateReceive(uint256, address sender, bytes data) external nonpayable
```

called by the exit helpers to either release the stake of a validator or slash it



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

### register

```solidity
function register(address validator_, uint256[2] signature, uint256[4] pubkey) external nonpayable
```

registers the public key of a validator



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator_ | address | undefined |
| signature | uint256[2] | undefined |
| pubkey | uint256[4] | undefined |

### whitelistValidators

```solidity
function whitelistValidators(address[] validators_) external nonpayable
```

Allows to whitelist validators that are allowed to stake

*only callable by owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| validators_ | address[] | undefined |

### withdrawSlashedStake

```solidity
function withdrawSlashedStake(address to) external nonpayable
```

Withdraws slashed MATIC of slashed validators

*only callable by owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |



## Events

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### ValidatorDeactivated

```solidity
event ValidatorDeactivated(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator  | address | undefined |

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


