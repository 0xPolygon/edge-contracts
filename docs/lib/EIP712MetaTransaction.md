# EIP712MetaTransaction









## Methods

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

### invalidateNext

```solidity
function invalidateNext(uint256 offset) external nonpayable
```



*Invalidates next &quot;offset&quot; number of nonces for the calling address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| offset | uint256 | undefined |



## Events

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



