# TestSignatureAggregator





test signature aggregator. the aggregated signature is the SUM of the nonce fields..



## Methods

### addStake

```solidity
function addStake(contract IEntryPoint entryPoint, uint32 delay) external payable
```

Calls the &#39;addStake&#39; method of the EntryPoint. Forwards the entire msg.value to this call.



#### Parameters

| Name | Type | Description |
|---|---|---|
| entryPoint | contract IEntryPoint | - the EntryPoint to send the stake to. |
| delay | uint32 | - the new lock duration before the deposit can be withdrawn. |

### aggregateSignatures

```solidity
function aggregateSignatures(UserOperation[] userOps) external pure returns (bytes aggregatedSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOps | UserOperation[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| aggregatedSignature | bytes | undefined |

### validateSignatures

```solidity
function validateSignatures(UserOperation[] userOps, bytes signature) external pure
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOps | UserOperation[] | undefined |
| signature | bytes | undefined |

### validateUserOpSignature

```solidity
function validateUserOpSignature(UserOperation) external pure returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | UserOperation | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |




