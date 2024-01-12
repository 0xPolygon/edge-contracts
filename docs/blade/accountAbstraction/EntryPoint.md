# EntryPoint









## Methods

### SIG_VALIDATION_FAILED

```solidity
function SIG_VALIDATION_FAILED() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _validateSenderAndPaymaster

```solidity
function _validateSenderAndPaymaster(bytes initCode, address sender, bytes paymasterAndData) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| initCode | bytes | undefined |
| sender | address | undefined |
| paymasterAndData | bytes | undefined |

### addStake

```solidity
function addStake(uint32 unstakeDelaySec) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| unstakeDelaySec | uint32 | undefined |

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### depositTo

```solidity
function depositTo(address account) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### deposits

```solidity
function deposits(address) external view returns (uint112 deposit, bool staked, uint112 stake, uint32 unstakeDelaySec, uint48 withdrawTime)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deposit | uint112 | undefined |
| staked | bool | undefined |
| stake | uint112 | undefined |
| unstakeDelaySec | uint32 | undefined |
| withdrawTime | uint48 | undefined |

### getDepositInfo

```solidity
function getDepositInfo(address account) external view returns (struct IAAStakeManager.DepositInfo info)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| info | IAAStakeManager.DepositInfo | undefined |

### getNonce

```solidity
function getNonce(address sender, uint192 key) external view returns (uint256 nonce)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | undefined |
| key | uint192 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| nonce | uint256 | undefined |

### getSenderAddress

```solidity
function getSenderAddress(bytes initCode) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| initCode | bytes | undefined |

### getUserOpHash

```solidity
function getUserOpHash(UserOperation userOp) external view returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### handleAggregatedOps

```solidity
function handleAggregatedOps(IEntryPoint.UserOpsPerAggregator[] opsPerAggregator, address payable beneficiary) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| opsPerAggregator | IEntryPoint.UserOpsPerAggregator[] | undefined |
| beneficiary | address payable | undefined |

### handleOps

```solidity
function handleOps(UserOperation[] ops, address payable beneficiary) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| ops | UserOperation[] | undefined |
| beneficiary | address payable | undefined |

### incrementNonce

```solidity
function incrementNonce(uint192 key) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | uint192 | undefined |

### innerHandleOp

```solidity
function innerHandleOp(bytes callData, EntryPoint.UserOpInfo opInfo, bytes context) external nonpayable returns (uint256 actualGasCost)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| callData | bytes | undefined |
| opInfo | EntryPoint.UserOpInfo | undefined |
| context | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| actualGasCost | uint256 | undefined |

### nonceSequenceNumber

```solidity
function nonceSequenceNumber(address, uint192) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint192 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### simulateHandleOp

```solidity
function simulateHandleOp(UserOperation op, address target, bytes targetCallData) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| op | UserOperation | undefined |
| target | address | undefined |
| targetCallData | bytes | undefined |

### simulateValidation

```solidity
function simulateValidation(UserOperation userOp) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |

### unlockStake

```solidity
function unlockStake() external nonpayable
```






### withdrawStake

```solidity
function withdrawStake(address payable withdrawAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | undefined |

### withdrawTo

```solidity
function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | undefined |
| withdrawAmount | uint256 | undefined |



## Events

### AccountDeployed

```solidity
event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOpHash `indexed` | bytes32 | undefined |
| sender `indexed` | address | undefined |
| factory  | address | undefined |
| paymaster  | address | undefined |

### BeforeExecution

```solidity
event BeforeExecution()
```






### Deposited

```solidity
event Deposited(address indexed account, uint256 totalDeposit)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| totalDeposit  | uint256 | undefined |

### SignatureAggregatorChanged

```solidity
event SignatureAggregatorChanged(address indexed aggregator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| aggregator `indexed` | address | undefined |

### StakeLocked

```solidity
event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| totalStaked  | uint256 | undefined |
| unstakeDelaySec  | uint256 | undefined |

### StakeUnlocked

```solidity
event StakeUnlocked(address indexed account, uint256 withdrawTime)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| withdrawTime  | uint256 | undefined |

### StakeWithdrawn

```solidity
event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| withdrawAddress  | address | undefined |
| amount  | uint256 | undefined |

### UserOperationEvent

```solidity
event UserOperationEvent(bytes32 indexed userOpHash, address indexed sender, address indexed paymaster, uint256 nonce, bool success, uint256 actualGasCost, uint256 actualGasUsed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOpHash `indexed` | bytes32 | undefined |
| sender `indexed` | address | undefined |
| paymaster `indexed` | address | undefined |
| nonce  | uint256 | undefined |
| success  | bool | undefined |
| actualGasCost  | uint256 | undefined |
| actualGasUsed  | uint256 | undefined |

### UserOperationRevertReason

```solidity
event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOpHash `indexed` | bytes32 | undefined |
| sender `indexed` | address | undefined |
| nonce  | uint256 | undefined |
| revertReason  | bytes | undefined |

### Withdrawn

```solidity
event Withdrawn(address indexed account, address withdrawAddress, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| withdrawAddress  | address | undefined |
| amount  | uint256 | undefined |



## Errors

### ExecutionResult

```solidity
error ExecutionResult(uint256 preOpGas, uint256 paid, uint48 validAfter, uint48 validUntil, bool targetSuccess, bytes targetResult)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| preOpGas | uint256 | undefined |
| paid | uint256 | undefined |
| validAfter | uint48 | undefined |
| validUntil | uint48 | undefined |
| targetSuccess | bool | undefined |
| targetResult | bytes | undefined |

### FailedOp

```solidity
error FailedOp(uint256 opIndex, string reason)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| opIndex | uint256 | undefined |
| reason | string | undefined |

### SenderAddressResult

```solidity
error SenderAddressResult(address sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | undefined |

### SignatureValidationFailed

```solidity
error SignatureValidationFailed(address aggregator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| aggregator | address | undefined |

### ValidationResult

```solidity
error ValidationResult(IEntryPoint.ReturnInfo returnInfo, IAAStakeManager.StakeInfo senderInfo, IAAStakeManager.StakeInfo factoryInfo, IAAStakeManager.StakeInfo paymasterInfo)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| returnInfo | IEntryPoint.ReturnInfo | undefined |
| senderInfo | IAAStakeManager.StakeInfo | undefined |
| factoryInfo | IAAStakeManager.StakeInfo | undefined |
| paymasterInfo | IAAStakeManager.StakeInfo | undefined |

### ValidationResultWithAggregation

```solidity
error ValidationResultWithAggregation(IEntryPoint.ReturnInfo returnInfo, IAAStakeManager.StakeInfo senderInfo, IAAStakeManager.StakeInfo factoryInfo, IAAStakeManager.StakeInfo paymasterInfo, IEntryPoint.AggregatorStakeInfo aggregatorInfo)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| returnInfo | IEntryPoint.ReturnInfo | undefined |
| senderInfo | IAAStakeManager.StakeInfo | undefined |
| factoryInfo | IAAStakeManager.StakeInfo | undefined |
| paymasterInfo | IAAStakeManager.StakeInfo | undefined |
| aggregatorInfo | IEntryPoint.AggregatorStakeInfo | undefined |


