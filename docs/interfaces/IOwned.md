# IOwned









## Methods

### claimOwnership

```solidity
function claimOwnership() external nonpayable
```

allows proposed owner to claim ownership (step 2 of transferring ownership)

*can only be called by the new proposed owner*


### proposeOwner

```solidity
function proposeOwner(address payable _newOwner) external nonpayable
```

proposes a new owner (step 1 of transferring ownership)

*can only be called by the current owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address payable | address of new proposed owner |



## Events

### OwnershipProposed

```solidity
event OwnershipProposed(address indexed proposedOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proposedOwner `indexed` | address | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



