# IValidatorSet









## Methods

### EPOCH_SIZE

```solidity
function EPOCH_SIZE() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfAt

```solidity
function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### commitEpoch

```solidity
function commitEpoch(uint256 id, Epoch epoch) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| epoch | Epoch | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256 counter, address sender, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

### totalBlocks

```solidity
function totalBlocks(uint256 epochId) external view returns (uint256 length)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| length | uint256 | undefined |

### totalSupplyAt

```solidity
function totalSupplyAt(uint256 epochNumber) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### unstake

```solidity
function unstake(uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### withdraw

```solidity
function withdraw() external nonpayable
```









