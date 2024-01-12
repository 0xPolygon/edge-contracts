# SimpleAccountFactory





A sample factory contract for SimpleAccount A UserOperations &quot;initCode&quot; holds the address of the factory, and a method call (to createAccount, in this sample factory). The factory&#39;s createAccount returns the target account address even if it is already installed. This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.



## Methods

### accountImplementation

```solidity
function accountImplementation() external view returns (contract SimpleAccount)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract SimpleAccount | undefined |

### createAccount

```solidity
function createAccount(address owner, uint256 salt) external nonpayable returns (contract SimpleAccount ret)
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
| ret | contract SimpleAccount | undefined |

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




