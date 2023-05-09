# StateReceiver

*Polygon Technology (JD Kanani @jdkanani, @QEDK)*

> State Receiver

executes and relays the state data on the child chain



## Methods

### ALLOWLIST_PRECOMPILE

```solidity
function ALLOWLIST_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### BLOCKLIST_PRECOMPILE

```solidity
function BLOCKLIST_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### READ_ADDRESSLIST_GAS

```solidity
function READ_ADDRESSLIST_GAS() external view returns (uint256)
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

### commit

```solidity
function commit(StateReceiver.StateSyncCommitment commitment, bytes signature, bytes bitmap) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| commitment | StateReceiver.StateSyncCommitment | undefined |
| signature | bytes | undefined |
| bitmap | bytes | undefined |

### commitmentCounter

```solidity
function commitmentCounter() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### commitmentIds

```solidity
function commitmentIds(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### commitments

```solidity
function commitments(uint256) external view returns (uint256 startId, uint256 endId, bytes32 root)
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

### execute

```solidity
function execute(bytes32[] proof, StateReceiver.StateSync obj) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proof | bytes32[] | undefined |
| obj | StateReceiver.StateSync | undefined |

### getCommitmentByStateSyncId

```solidity
function getCommitmentByStateSyncId(uint256 id) external view returns (struct StateReceiver.StateSyncCommitment)
```

get commitment for a state sync id



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | state sync to get the root for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | StateReceiver.StateSyncCommitment | undefined |

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

### processedStateSyncs

```solidity
function processedStateSyncs(uint256) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### NewCommitment

```solidity
event NewCommitment(uint256 indexed startId, uint256 indexed endId, bytes32 root)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| startId `indexed` | uint256 | undefined |
| endId `indexed` | uint256 | undefined |
| root  | bytes32 | undefined |

### StateSyncResult

```solidity
event StateSyncResult(uint256 indexed counter, bool indexed status, bytes message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter `indexed` | uint256 | undefined |
| status `indexed` | bool | undefined |
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


