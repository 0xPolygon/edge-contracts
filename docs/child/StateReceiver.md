# StateReceiver

*Polygon Technology (JD Kanani @jdkanani, @QEDK)*

> State Receiver

executes and relays the state data on the child chain



## Methods

### NATIVE_TOKEN_CONTRACT

```solidity
function NATIVE_TOKEN_CONTRACT() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TRANSFER_PRECOMPILE

```solidity
function NATIVE_TRANSFER_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TRANSFER_PRECOMPILE_GAS

```solidity
function NATIVE_TRANSFER_PRECOMPILE_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### SYSTEM

```solidity
function SYSTEM() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### VALIDATOR_PKCHECK_PRECOMPILE

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### VALIDATOR_PKCHECK_PRECOMPILE_GAS

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### batchExecute

```solidity
function batchExecute(bytes32[][] proofs, StateReceiver.StateSync[] objs) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proofs | bytes32[][] | undefined |
| objs | StateReceiver.StateSync[] | undefined |

### bundleCounter

```solidity
function bundleCounter() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### bundles

```solidity
function bundles(uint256) external view returns (uint256 startId, uint256 endId, bytes32 root)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| startId | uint256 | undefined |
| endId | uint256 | undefined |
| root | bytes32 | undefined |

### commit

```solidity
function commit(StateReceiver.StateSyncBundle bundle, bytes signature, bytes bitmap) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| bundle | StateReceiver.StateSyncBundle | undefined |
| signature | bytes | undefined |
| bitmap | bytes | undefined |

### execute

```solidity
function execute(bytes32[] proof, StateReceiver.StateSync obj) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proof | bytes32[] | undefined |
| obj | StateReceiver.StateSync | undefined |

### getBundleByStateSyncId

```solidity
function getBundleByStateSyncId(uint256 id) external view returns (struct StateReceiver.StateSyncBundle)
```

get bundle for a state sync id



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | state sync to get the root for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | StateReceiver.StateSyncBundle | undefined |

### getRootByStateSyncId

```solidity
function getRootByStateSyncId(uint256 id) external view returns (bytes32)
```

get submitted root for a state sync id



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | state sync to get the root for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### lastCommittedId

```solidity
function lastCommittedId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### stateSyncBundleIds

```solidity
function stateSyncBundleIds(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### StateSyncResult

```solidity
event StateSyncResult(uint256 indexed counter, enum StateReceiver.ResultStatus indexed status, bytes message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter `indexed` | uint256 | undefined |
| status `indexed` | enum StateReceiver.ResultStatus | undefined |
| message  | bytes | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


