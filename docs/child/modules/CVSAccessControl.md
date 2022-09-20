# CVSAccessControl

## Methods

### ACTIVE_VALIDATOR_SET_SIZE

```solidity
function ACTIVE_VALIDATOR_SET_SIZE() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### MAX_COMMISSION

```solidity
function MAX_COMMISSION() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### MAX_VALIDATOR_SET_SIZE

```solidity
function MAX_VALIDATOR_SET_SIZE() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### NEW_VALIDATOR_SIG

```solidity
function NEW_VALIDATOR_SIG() external view returns (bytes32)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | bytes32 | undefined   |

### REWARD_PRECISION

```solidity
function REWARD_PRECISION() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### SPRINT

```solidity
function SPRINT() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### WITHDRAWAL_WAIT_PERIOD

```solidity
function WITHDRAWAL_WAIT_PERIOD() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### addToWhitelist

```solidity
function addToWhitelist(address[] whitelistAddreses) external nonpayable
```

Adds addresses that are allowed to register as validators.

#### Parameters

| Name              | Type      | Description                   |
| ----------------- | --------- | ----------------------------- |
| whitelistAddreses | address[] | Array of address to whitelist |

### bls

```solidity
function bls() external view returns (contract IBLS)
```

#### Returns

| Name | Type          | Description |
| ---- | ------------- | ----------- |
| \_0  | contract IBLS | undefined   |

### claimOwnership

```solidity
function claimOwnership() external nonpayable
```

allows proposed owner to claim ownership (step 2 of transferring ownership)

_can only be called by the new proposed owner_

### currentEpochId

```solidity
function currentEpochId() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### epochEndBlocks

```solidity
function epochEndBlocks(uint256) external view returns (uint256)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### epochReward

```solidity
function epochReward() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### epochs

```solidity
function epochs(uint256) external view returns (uint256 startBlock, uint256 endBlock, bytes32 epochRoot)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name       | Type    | Description |
| ---------- | ------- | ----------- |
| startBlock | uint256 | undefined   |
| endBlock   | uint256 | undefined   |
| epochRoot  | bytes32 | undefined   |

### getValidator

```solidity
function getValidator(address validator) external view returns (struct Validator)
```

Gets validator by address.

#### Parameters

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| validator | address | undefined   |

#### Returns

| Name | Type      | Description                                                                                            |
| ---- | --------- | ------------------------------------------------------------------------------------------------------ |
| \_0  | Validator | Validator (BLS public key, self-stake, total stake, commission, withdrawable rewards, activity status) |

### message

```solidity
function message(uint256) external view returns (uint256)
```

Message to sign for registration

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### minDelegation

```solidity
function minDelegation() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### minStake

```solidity
function minStake() external view returns (uint256)
```

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | uint256 | undefined   |

### owner

```solidity
function owner() external view returns (address)
```

the address of the owner

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### proposeOwner

```solidity
function proposeOwner(address payable newOwner) external nonpayable
```

proposes a new owner (step 1 of transferring ownership)

_can only be called by the current owner_

#### Parameters

| Name     | Type            | Description |
| -------- | --------------- | ----------- |
| newOwner | address payable | undefined   |

### proposedOwner

```solidity
function proposedOwner() external view returns (address)
```

the address of a proposed owner

#### Returns

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address[] whitelistAddreses) external nonpayable
```

Deletes addresses that are allowed to register as validators.

#### Parameters

| Name              | Type      | Description                               |
| ----------------- | --------- | ----------------------------------------- |
| whitelistAddreses | address[] | Array of address to remove from whitelist |

### whitelist

```solidity
function whitelist(address) external view returns (bool)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| \_0  | address | undefined   |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

## Events

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |

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

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```

#### Parameters

| Name                | Type    | Description |
| ------------------- | ------- | ----------- |
| validator `indexed` | address | undefined   |

## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```

#### Parameters

| Name | Type   | Description |
| ---- | ------ | ----------- |
| only | string | undefined   |
