# TestAggregatedAccountFactory





Based on SimpleAccountFactory. Cannot be a subclass since both constructor and createAccount depend on the constructor and initializer of the actual account contract.



## Methods

### accountImplementation

```solidity
function accountImplementation() external view returns (contract TestAggregatedAccount)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract TestAggregatedAccount | undefined |

### createAccount

```solidity
function createAccount(address owner, uint256 salt) external nonpayable returns (contract TestAggregatedAccount ret)
```

create an account, and return its address. returns the address even if the account is already deployed. Note that during UserOperation execution, this method is called only if the account is not deployed. This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| salt | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| ret | contract TestAggregatedAccount | undefined |

### getAddress

```solidity
function getAddress(address owner, uint256 salt) external view returns (address)
```

calculate the counterfactual address of this account as it would be returned by createAccount()



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| salt | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |




