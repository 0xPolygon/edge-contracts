# ICVSStorage









## Methods

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




## Errors

### InvalidSignature

```solidity
error InvalidSignature(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |


