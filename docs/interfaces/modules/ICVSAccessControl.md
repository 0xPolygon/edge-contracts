# ICVSAccessControl









## Methods

### addToWhitelist

```solidity
function addToWhitelist(address[] whitelistAddreses) external nonpayable
```

Adds addresses that are allowed to register as validators.



#### Parameters

| Name | Type | Description |
|---|---|---|
| whitelistAddreses | address[] | Array of address to whitelist |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address[] whitelistAddreses) external nonpayable
```

Deletes addresses that are allowed to register as validators.



#### Parameters

| Name | Type | Description |
|---|---|---|
| whitelistAddreses | address[] | Array of address to remove from whitelist |

### setSprint

```solidity
function setSprint(uint256 newSprint) external nonpayable
```

Set the amount of blocks per epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| newSprint | uint256 | the new amount of blocks per epoch |



## Events

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### SprintUpdated

```solidity
event SprintUpdated(uint256 oldSprint, uint256 newSprint)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldSprint  | uint256 | undefined |
| newSprint  | uint256 | undefined |



