# Owned

## Methods

### claimOwnership

```solidity
function claimOwnership() external nonpayable
```

_can only be called by the new proposed owner_

### owner

```solidity
function owner() external view returns (address)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### proposeOwner

```solidity
function proposeOwner(address payable newOwner) external nonpayable
```

_can only be called by the new current owner_

#### Parameters

| Name     | Type            | Description |
| -------- | --------------- | ----------- |
| newOwner | address payable | undefined   |

### proposedOwner

```solidity
function proposedOwner() external view returns (address)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

## Events

### Initialized

```solidity
event Initialized(uint8 version)
```

#### Parameters

| Name    | Type  | Description |
| ------- | ----- | ----------- |
| version | uint8 | undefined   |

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

## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```

#### Parameters

| Name | Type   | Description |
| ---- | ------ | ----------- |
| only | string | undefined   |
