# ValidatorSetHardforkProxy





ValidatorSet-specific proxy for hardfork migration

*If starting fresh, use GenesisProxy instead*

## Methods

### setUpProxy

```solidity
function setUpProxy(address logic, address admin, address newNetworkParams) external nonpayable
```

function for initializing proxy for the ValidatorSet genesis contract

*meant to be deployed during genesis*

#### Parameters

| Name | Type | Description |
|---|---|---|
| logic | address | the address of the implementation (logic) contract for the validator set |
| admin | address | the address that has permission to update what address contains the implementation |
| newNetworkParams | address | address of genesis contract NetworkParams |



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



