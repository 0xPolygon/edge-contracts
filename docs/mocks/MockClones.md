# MockClones







*https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for deploying minimal proxy contracts, also known as &quot;clones&quot;. &gt; To simply and cheaply clone contract functionality in an immutable way, this standard specifies &gt; a minimal bytecode implementation that delegates all calls to a known, fixed address. The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2` (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the deterministic method. _Available since v3.4._*

## Methods

### predictDeterministicAddress

```solidity
function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) external pure returns (address predicted)
```



*Computes the address of a clone deployed using {Clones-cloneDeterministic}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation | address | undefined |
| salt | bytes32 | undefined |
| deployer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| predicted | address | undefined |




