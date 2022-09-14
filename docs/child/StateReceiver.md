# StateReceiver

## Methods

### NATIVE_TOKEN_CONTRACT

```solidity
function NATIVE_TOKEN_CONTRACT() external view returns (address)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### NATIVE_TRANSFER_PRECOMPILE

```solidity
function NATIVE_TRANSFER_PRECOMPILE() external view returns (address)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### NATIVE_TRANSFER_PRECOMPILE_GAS

```solidity
function NATIVE_TRANSFER_PRECOMPILE_GAS() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### SYSTEM

```solidity
function SYSTEM() external view returns (address)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### VALIDATOR_PKCHECK_PRECOMPILE

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE() external view returns (address)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### VALIDATOR_PKCHECK_PRECOMPILE_GAS

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE_GAS() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### bundleCounter

```solidity
function bundleCounter() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### bundles

```solidity
function bundles(uint256) external view returns (uint256 startId, uint256 endId, uint256 leaves, bytes32 root)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name    | Type    | Description |
| ------- | ------- | ----------- |
| startId | uint256 | undefined   |
| endId   | uint256 | undefined   |
| leaves  | uint256 | undefined   |
| root    | bytes32 | undefined   |

### commit

```solidity
function commit(StateReceiver.StateSyncBundle bundle, bytes signature, uint256[] validatorIds) external nonpayable
```

#### Parameters

| Name         | Type                          | Description |
| ------------ | ----------------------------- | ----------- |
| bundle       | StateReceiver.StateSyncBundle | undefined   |
| signature    | bytes                         | undefined   |
| validatorIds | uint256[]                     | undefined   |

### counter

```solidity
function counter() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### currentLeafIndex

```solidity
function currentLeafIndex() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### execute

```solidity
function execute(bytes32[] proof, StateReceiver.StateSync[] objs) external nonpayable
```

#### Parameters

| Name  | Type                      | Description |
| ----- | ------------------------- | ----------- |
| proof | bytes32[]                 | undefined   |
| objs  | StateReceiver.StateSync[] | undefined   |

### lastCommittedId

```solidity
function lastCommittedId() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### lastExecutedBundleCounter

```solidity
function lastExecutedBundleCounter() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

## Events

### StateSyncResult

```solidity
event StateSyncResult(uint256 indexed counter, enum StateReceiver.ResultStatus indexed status, bytes32 message)
```

#### Parameters

| Name              | Type                            | Description |
| ----------------- | ------------------------------- | ----------- |
| counter `indexed` | uint256                         | undefined   |
| status `indexed`  | enum StateReceiver.ResultStatus | undefined   |
| message           | bytes32                         | undefined   |

## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```

#### Parameters

| Name | Type   | Description |
| ---- | ------ | ----------- |
| only | string | undefined   |
