# IOwned

## Methods

### claimOwnership

```solidity
function claimOwnership() external nonpayable
```

claim ownership of the contract

### proposeOwner

```solidity
function proposeOwner(address payable _newOwner) external nonpayable
```

propeses a new owner

#### Parameters

| Name       | Type            | Description                   |
| ---------- | --------------- | ----------------------------- |
| \_newOwner | address payable | address of new proposed owner |

## Events

### OwnershipProposed

```solidity
event OwnershipProposed(address indexed proposedOwner)
```

#### Parameters

| Name                    | Type    | Description |
| ----------------------- | ------- | ----------- |
| proposedOwner `indexed` | address | undefined   |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```

#### Parameters

| Name                    | Type    | Description |
| ----------------------- | ------- | ----------- |
| previousOwner `indexed` | address | undefined   |
| newOwner `indexed`      | address | undefined   |
