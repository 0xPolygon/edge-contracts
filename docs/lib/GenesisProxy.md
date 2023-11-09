# GenesisProxy

*Polygon Technology*

> GenesisProxy

wrapper for OpenZeppelin&#39;s Transparent Upgreadable Proxy, intended for use during genesis for genesis contractsone GenesisProxy should be deployed for each genesis contract



## Methods

### protectSetUpProxy

```solidity
function protectSetUpProxy(address initiator) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| initiator | address | undefined |

### setUpProxy

```solidity
function setUpProxy(address logic, address admin, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| logic | address | undefined |
| admin | address | undefined |
| data | bytes | undefined |



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



