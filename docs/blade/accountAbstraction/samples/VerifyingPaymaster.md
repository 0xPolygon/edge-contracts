# VerifyingPaymaster





A sample paymaster that uses external service to decide whether to pay for the UserOp. The paymaster trusts an external signer to sign the transaction. The calling user must pass the UserOp to that external signer first, which performs whatever off-chain verification before signing the UserOp. Note that this signature is NOT a replacement for the account-specific signature: - the paymaster checks a signature to agree to PAY for GAS. - the account checks a signature to prove identity and account ownership.



## Methods

### addStake

```solidity
function addStake(uint32 unstakeDelaySec) external payable
```

add stake for this paymaster. This method can also carry eth value to add to the current stake.



#### Parameters

| Name | Type | Description |
|---|---|---|
| unstakeDelaySec | uint32 | - the unstake delay for this paymaster. Can only be increased. |

### deposit

```solidity
function deposit() external payable
```

add a deposit for this paymaster, used for paying for transaction fees




### entryPoint

```solidity
function entryPoint() external view returns (contract IEntryPoint)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IEntryPoint | undefined |

### getDeposit

```solidity
function getDeposit() external view returns (uint256)
```

return current paymaster&#39;s deposit on the entryPoint.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getHash

```solidity
function getHash(UserOperation userOp, uint48 validUntil, uint48 validAfter) external view returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |
| validUntil | uint48 | undefined |
| validAfter | uint48 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### parsePaymasterAndData

```solidity
function parsePaymasterAndData(bytes paymasterAndData) external pure returns (uint48 validUntil, uint48 validAfter, bytes signature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| paymasterAndData | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| validUntil | uint48 | undefined |
| validAfter | uint48 | undefined |
| signature | bytes | undefined |

### postOp

```solidity
function postOp(enum IPaymaster.PostOpMode mode, bytes context, uint256 actualGasCost) external nonpayable
```

post-operation handler. Must verify sender is the entryPoint



#### Parameters

| Name | Type | Description |
|---|---|---|
| mode | enum IPaymaster.PostOpMode | enum with the following options:      opSucceeded - user operation succeeded.      opReverted  - user op reverted. still has to pay for gas.      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.                       Now this is the 2nd call, after user&#39;s op was deliberately reverted. |
| context | bytes | - the context value returned by validatePaymasterUserOp |
| actualGasCost | uint256 | - actual gas used so far (without this postOp call). |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### senderNonce

```solidity
function senderNonce(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### unlockStake

```solidity
function unlockStake() external nonpayable
```

unlock the stake, in order to withdraw it. The paymaster can&#39;t serve requests once unlocked, until it calls addStake again




### validatePaymasterUserOp

```solidity
function validatePaymasterUserOp(UserOperation userOp, bytes32 userOpHash, uint256 maxCost) external nonpayable returns (bytes context, uint256 validationData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |
| userOpHash | bytes32 | undefined |
| maxCost | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| context | bytes | undefined |
| validationData | uint256 | undefined |

### verifyingSigner

```solidity
function verifyingSigner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### withdrawStake

```solidity
function withdrawStake(address payable withdrawAddress) external nonpayable
```

withdraw the entire paymaster&#39;s stake. stake must be unlocked first (and then wait for the unstakeDelay to be over)



#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | the address to send withdrawn value. |

### withdrawTo

```solidity
function withdrawTo(address payable withdrawAddress, uint256 amount) external nonpayable
```

withdraw value from the deposit



#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | target to send to |
| amount | uint256 | to withdraw |



## Events

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



