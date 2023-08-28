# GenesisProxy

*Polygon Technology*

> GenesisProxy

wrapper for OpenZeppelin&#39;s Transparent Upgreadable Proxy, intended for use during genesis for genesis contractsone GenesisProxy should be deployed for each genesis contract, but there are exceptions if hardforking - see below

*If hardforking, for ValidatorSet, RewardPool, ForkParams, and NetworkParams, use the respective dedicated HardforkProxy instead*

## Methods

### setUpProxy

```solidity
function setUpProxy(address logic, address admin, bytes data) external nonpayable
```

function for initializing proxy



#### Parameters

| Name | Type | Description |
|---|---|---|
| logic | address | the address of the implementation (logic) contract for the genesis contract |
| admin | address | the address that has permission to update what address contains the implementation |
| data | bytes | raw calldata for the intialization of the genesis contract (if required) |



## Events

### AdminChanged

```solidity
event AdminChanged(address previousAdmin, address newAdmin)
```



*Emitted when the admin account has changed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| previousAdmin  | address | undefined |
| newAdmin  | address | undefined |

### BeaconUpgraded

```solidity
event BeaconUpgraded(address indexed beacon)
```



*Emitted when the beacon is changed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| beacon `indexed` | address | undefined |

### Upgraded

```solidity
event Upgraded(address indexed implementation)
```



*Emitted when the implementation is upgraded.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation `indexed` | address | undefined |



