# ChildERC1155

*Polygon Technology (@QEDK, @wschwab)*

> ChildERC1155

Child token template for ChildERC1155 predicate deployments

*All child tokens are clones of this contract. Burning and minting is controlled by respective predicates only.*

## Methods

### balanceOf

```solidity
function balanceOf(address account, uint256 id) external view returns (uint256)
```



*See {IERC1155-balanceOf}. Requirements: - `account` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfBatch

```solidity
function balanceOfBatch(address[] accounts, uint256[] ids) external view returns (uint256[])
```



*See {IERC1155-balanceOfBatch}. Requirements: - `accounts` and `ids` must have the same length.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |
| ids | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### burn

```solidity
function burn(address from, uint256 id, uint256 amount) external nonpayable returns (bool)
```

Burns an NFT tokens from a particular address

*Can only be called by the predicate address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | Address to burn the NFTs from |
| id | uint256 | Index of NFT to burn from the account |
| amount | uint256 | Amount of NFT to burn |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is succesful |

### burnBatch

```solidity
function burnBatch(address from, uint256[] tokenIds, uint256[] amounts) external nonpayable returns (bool)
```

Burns multiple NFTs from one address

*included for compliance with the general format of EIP-1155*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | Address to burn NFTs from |
| tokenIds | uint256[] | Array of indexes of the NFTs to be minted |
| amounts | uint256[] | Array of the amount of each NFT to be minted |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is successful |

### executeMetaTransaction

```solidity
function executeMetaTransaction(address userAddress, bytes functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) external nonpayable returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |
| functionSignature | bytes | undefined |
| sigR | bytes32 | undefined |
| sigS | bytes32 | undefined |
| sigV | uint8 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getNonce

```solidity
function getNonce(address user) external view returns (uint256 nonce)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| nonce | uint256 | undefined |

### initialize

```solidity
function initialize(address rootToken_, string uri_) external nonpayable
```



*Sets the value for {rootToken} and {uri_} This value is immutable: it can only be set once during initialization.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken_ | address | undefined |
| uri_ | string | undefined |

### invalidateNext

```solidity
function invalidateNext(uint256 offset) external nonpayable
```



*Invalidates next &quot;offset&quot; number of nonces for the calling address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| offset | uint256 | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address account, address operator) external view returns (bool)
```



*See {IERC1155-isApprovedForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### mint

```solidity
function mint(address account, uint256 id, uint256 amount) external nonpayable returns (bool)
```

Mints an NFT token to a particular address

*Can only be called by the predicate address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | Account of the user to mint the tokens to |
| id | uint256 | Index of NFT to mint to the account |
| amount | uint256 | Amount of NFT to mint |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is succesful |

### mintBatch

```solidity
function mintBatch(address[] accounts, uint256[] tokenIds, uint256[] amounts) external nonpayable returns (bool)
```

Mints multiple NFTs to one address

*single destination for compliance with the general format of EIP-1155*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | Array of addresses to mint each NFT to |
| tokenIds | uint256[] | Array of indexes of the NFTs to be minted |
| amounts | uint256[] | Array of the amount of each NFT to be minted |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is successful |

### predicate

```solidity
function predicate() external view returns (address)
```

Returns predicate address controlling the child token




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address Returns the address of the predicate |

### rootToken

```solidity
function rootToken() external view returns (address)
```

Returns address of the token on the root chain




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address Returns the address of the predicate |

### safeBatchTransferFrom

```solidity
function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) external nonpayable
```



*See {IERC1155-safeBatchTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| ids | uint256[] | undefined |
| amounts | uint256[] | undefined |
| data | bytes | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) external nonpayable
```



*See {IERC1155-safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |
| amount | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*See {IERC1155-setApprovalForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| approved | bool | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### uri

```solidity
function uri(uint256) external view returns (string)
```



*See {IERC1155MetadataURI-uri}. This implementation returns the same URI for *all* token types. It relies on the token type ID substitution mechanism https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP]. Clients calling this function must replace the `\{id\}` substring with the actual token type ID.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |



## Events

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed account, address indexed operator, bool approved)
```



*Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to `approved`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| approved  | bool | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### MetaTransactionExecuted

```solidity
event MetaTransactionExecuted(address userAddress, address relayerAddress, bytes functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress  | address | undefined |
| relayerAddress  | address | undefined |
| functionSignature  | bytes | undefined |

### TransferBatch

```solidity
event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
```



*Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| ids  | uint256[] | undefined |
| values  | uint256[] | undefined |

### TransferSingle

```solidity
event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
```



*Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| id  | uint256 | undefined |
| value  | uint256 | undefined |

### URI

```solidity
event URI(string value, uint256 indexed id)
```



*Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI. If an {URI} event was emitted for `id`, the standard https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value returned by {IERC1155MetadataURI-uri}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| value  | string | undefined |
| id `indexed` | uint256 | undefined |



