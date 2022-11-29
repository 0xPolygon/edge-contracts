# IChildValidatorSetBase

*Polygon Technology*

> ChildValidatorSet

Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.

*The contract is used to complete validator registration and store self-stake and delegated MATIC amounts. It manages staking, epoch committing, and reward distribution.*

## Methods

### commitEpoch

```solidity
function commitEpoch(uint256 id, Epoch epoch, Uptime uptime) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| epoch | Epoch | undefined |
| uptime | Uptime | undefined |

### commitEpochWithDoubleSignerSlashing

```solidity
function commitEpochWithDoubleSignerSlashing(uint256 curEpochId, Epoch epoch, Uptime uptime, uint256 blockNumber, uint256 pbftRound, uint256 epochId, IChildValidatorSetBase.DoubleSignerSlashingInput[] inputs) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| curEpochId | uint256 | undefined |
| epoch | Epoch | undefined |
| uptime | Uptime | undefined |
| blockNumber | uint256 | undefined |
| pbftRound | uint256 | undefined |
| epochId | uint256 | undefined |
| inputs | IChildValidatorSetBase.DoubleSignerSlashingInput[] | undefined |

### getCurrentValidatorSet

```solidity
function getCurrentValidatorSet() external view returns (address[])
```

Gets addresses of active validators in this epoch, sorted by total stake (self-stake + delegation)




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | Array of addresses of active validators in this epoch, sorted by total stake |

### getEpochByBlock

```solidity
function getEpochByBlock(uint256 blockNumber) external view returns (struct Epoch)
```

Look up an epoch by block number. Searches in O(log n) time.



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | ID of epoch to be committed |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | Epoch | Epoch Returns epoch if found, or else, the last epoch |

### totalActiveStake

```solidity
function totalActiveStake() external view returns (uint256)
```

Calculates total stake of active validators (self-stake + delegation).




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Total stake of active validators (in MATIC wei) |



## Events

### DoubleSignerSlashed

```solidity
event DoubleSignerSlashed(address indexed key, uint256 indexed epoch, uint256 indexed pbftRound)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key `indexed` | address | undefined |
| epoch `indexed` | uint256 | undefined |
| pbftRound `indexed` | uint256 | undefined |

### NewEpoch

```solidity
event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| startBlock `indexed` | uint256 | undefined |
| endBlock `indexed` | uint256 | undefined |
| epochRoot  | bytes32 | undefined |



