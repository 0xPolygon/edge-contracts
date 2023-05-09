# IBLS









## Methods

### expandMsgTo96

```solidity
function expandMsgTo96(bytes32 domain, bytes message) external pure returns (bytes)
```

pads messages less than 96 bytes to 96 bytes for hashing



#### Parameters

| Name | Type | Description |
|---|---|---|
| domain | bytes32 | domain separator for the hash |
| message | bytes | the message to pad |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | bytes the padded message |

### hashToField

```solidity
function hashToField(bytes32 domain, bytes messages) external view returns (uint256[2])
```

hashes an arbitrary message to a field element



#### Parameters

| Name | Type | Description |
|---|---|---|
| domain | bytes32 | domain separator for the hash |
| messages | bytes | the messages to map |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[2] | uint256[2] (x,y) point of the field element that the message maps to |

### hashToPoint

```solidity
function hashToPoint(bytes32 domain, bytes message) external view returns (uint256[2])
```

hashes an arbitrary message to a point on the curve

*Fouque-Tibouchi Hash to Curve*

#### Parameters

| Name | Type | Description |
|---|---|---|
| domain | bytes32 | domain separator for the hash |
| message | bytes | the message to map |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[2] | uint256[2] (x,y) point on the curve that the message maps to |

### isOnCurveG1

```solidity
function isOnCurveG1(uint256[2] point) external pure returns (bool _isOnCurve)
```

checks if point in the finite field Fq (x,y) is on the G1 curve



#### Parameters

| Name | Type | Description |
|---|---|---|
| point | uint256[2] | array with x and y values of the point |

#### Returns

| Name | Type | Description |
|---|---|---|
| _isOnCurve | bool | bool indicating if the point is on the curve or not |

### isOnCurveG2

```solidity
function isOnCurveG2(uint256[4] point) external pure returns (bool _isOnCurve)
```

checks if point in the finite field Fq (x,y) is on the G2 curve



#### Parameters

| Name | Type | Description |
|---|---|---|
| point | uint256[4] | array with x and y values of the point |

#### Returns

| Name | Type | Description |
|---|---|---|
| _isOnCurve | bool | bool indicating if the point is on the curve or not |

### isValidSignature

```solidity
function isValidSignature(uint256[2] signature) external view returns (bool)
```

checks if a signature is formatted correctly and valid

*will revert if improperly formatted, will return false if invalid*

#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | the BLS signature |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool indicating if the signature is valid or not |

### mapToPoint

```solidity
function mapToPoint(uint256 _x) external pure returns (uint256[2] p)
```

maps a field element to the curve



#### Parameters

| Name | Type | Description |
|---|---|---|
| _x | uint256 | a valid field element |

#### Returns

| Name | Type | Description |
|---|---|---|
| p | uint256[2] | the point on the curve the point is mapped to |

### verifyMultiple

```solidity
function verifyMultiple(uint256[2] signature, uint256[4][] pubkeys, uint256[2][] messages) external view returns (bool checkResult, bool callSuccess)
```

verifies multiple non-aggregated signatures where each message is unique



#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | 64-byte G1 group element (small sig) |
| pubkeys | uint256[4][] | array of 128-byte G2 group element (big pubkey) |
| messages | uint256[2][] | array of messages signed to produce signature |

#### Returns

| Name | Type | Description |
|---|---|---|
| checkResult | bool | bool indicating sig verification |
| callSuccess | bool | bool indicating call success |

### verifyMultipleSameMsg

```solidity
function verifyMultipleSameMsg(uint256[2] signature, uint256[4][] pubkeys, uint256[2] message) external view returns (bool checkResult, bool callSuccess)
```

verifies an aggregated signature where the same message is signed



#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | 64-byte G1 group element (small sig) |
| pubkeys | uint256[4][] | array of 128-byte G2 group element (big pubkey) |
| message | uint256[2] | message signed by all to produce signature |

#### Returns

| Name | Type | Description |
|---|---|---|
| checkResult | bool | sig verification |
| callSuccess | bool | indicating call success |

### verifySingle

```solidity
function verifySingle(uint256[2] signature, uint256[4] pubkey, uint256[2] message) external view returns (bool, bool)
```

verifies a single signature



#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | 64-byte G1 group element (small sig) |
| pubkey | uint256[4] | 128-byte G2 group element (big pubkey) |
| message | uint256[2] | message signed to produce signature |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool sig verification |
| _1 | bool | bool indicating call success |




