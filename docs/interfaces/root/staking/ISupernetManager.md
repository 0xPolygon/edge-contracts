# ISupernetManager

*Polygon Technology (@gretzke)*

> ISupernetManager

Abstract contract for managing supernets

*Should be implemented with custom desired functionality*

## Methods

### onInit

```solidity
function onInit(uint256 id) external nonpayable
```

called when a new child chain is registered



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

### onStake

```solidity
function onStake(address validator, uint256 amount) external nonpayable
```

called when a validator stakes



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| amount | uint256 | undefined |




