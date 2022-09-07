# IBLS

## Methods

### expandMsgTo96

```solidity
function expandMsgTo96(bytes32 domain, bytes message) external pure returns (bytes)
```

#### Parameters

| Name    | Type    | Description |
| ------- | ------- | ----------- |
| domain  | bytes32 | undefined   |
| message | bytes   | undefined   |

#### Returns

| Name | Type  | Description |
| ---- | ----- | ----------- |
| \_0  | bytes | undefined   |

### hashToField

```solidity
function hashToField(bytes32 domain, bytes messages) external view returns (uint256[2])
```

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| domain   | bytes32 | undefined   |
| messages | bytes   | undefined   |

#### Returns

| Name | Type       | Description |
| ---- | ---------- | ----------- |
| \_0  | uint256[2] | undefined   |

### hashToPoint

```solidity
function hashToPoint(bytes32 domain, bytes message) external view returns (uint256[2])
```

#### Parameters

| Name    | Type    | Description |
| ------- | ------- | ----------- |
| domain  | bytes32 | undefined   |
| message | bytes   | undefined   |

#### Returns

| Name | Type       | Description |
| ---- | ---------- | ----------- |
| \_0  | uint256[2] | undefined   |

### isOnCurveG1

```solidity
function isOnCurveG1(uint256[2] point) external pure returns (bool _isOnCurve)
```

#### Parameters

| Name  | Type       | Description |
| ----- | ---------- | ----------- |
| point | uint256[2] | undefined   |

#### Returns

| Name        | Type | Description |
| ----------- | ---- | ----------- |
| \_isOnCurve | bool | undefined   |

### isValidSignature

```solidity
function isValidSignature(uint256[2] signature) external view returns (bool)
```

#### Parameters

| Name      | Type       | Description |
| --------- | ---------- | ----------- |
| signature | uint256[2] | undefined   |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

### mapToPoint

```solidity
function mapToPoint(uint256 _x) external pure returns (uint256[2] p)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_x  | uint256 | undefined   |

#### Returns

| Name | Type       | Description |
| ---- | ---------- | ----------- |
| p    | uint256[2] | undefined   |

### verifyMultiple

```solidity
function verifyMultiple(uint256[2] signature, uint256[4][] pubkeys, uint256[2][] messages) external view returns (bool checkResult, bool callSuccess)
```

#### Parameters

| Name      | Type         | Description |
| --------- | ------------ | ----------- |
| signature | uint256[2]   | undefined   |
| pubkeys   | uint256[4][] | undefined   |
| messages  | uint256[2][] | undefined   |

#### Returns

| Name        | Type | Description |
| ----------- | ---- | ----------- |
| checkResult | bool | undefined   |
| callSuccess | bool | undefined   |

### verifyMultipleSameMsg

```solidity
function verifyMultipleSameMsg(uint256[2] signature, uint256[4][] pubkeys, uint256[2] message) external view returns (bool checkResult, bool callSuccess)
```

#### Parameters

| Name      | Type         | Description |
| --------- | ------------ | ----------- |
| signature | uint256[2]   | undefined   |
| pubkeys   | uint256[4][] | undefined   |
| message   | uint256[2]   | undefined   |

#### Returns

| Name        | Type | Description |
| ----------- | ---- | ----------- |
| checkResult | bool | undefined   |
| callSuccess | bool | undefined   |

### verifySingle

```solidity
function verifySingle(uint256[2] signature, uint256[4] pubkey, uint256[2] message) external view returns (bool, bool)
```

#### Parameters

| Name      | Type       | Description |
| --------- | ---------- | ----------- |
| signature | uint256[2] | undefined   |
| pubkey    | uint256[4] | undefined   |
| message   | uint256[2] | undefined   |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |
| \_1  | bool | undefined   |
