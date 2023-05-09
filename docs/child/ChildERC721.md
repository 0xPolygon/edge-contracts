# ChildERC721

*Polygon Technology (@QEDK, @wschwab)*

> ChildERC721

Child token template for ChildERC721 predicate deployments

*All child tokens are clones of this contract. Burning and minting is controlled by respective predicates only.*

## Methods

### approve

```solidity
function approve(address to, uint256 tokenId) external nonpayable
```



*See {IERC721-approve}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| tokenId | uint256 | undefined |

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256)
```



*See {IERC721-balanceOf}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### burn

```solidity
function burn(address account, uint256 tokenId) external nonpayable returns (bool)
```

Burns an NFT tokens from a particular address

*Can only be called by the predicate address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | Address to burn the NFTs from |
| tokenId | uint256 | Index of NFT to burn |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is succesful |

### burnBatch

```solidity
function burnBatch(address account, uint256[] tokenIds) external nonpayable returns (bool)
```

Burns multiple NFTs in one transaction



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | Address to burn the NFTs from |
| tokenIds | uint256[] | Array of NFT indexes to burn |

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

### getApproved

```solidity
function getApproved(uint256 tokenId) external view returns (address)
```



*See {IERC721-getApproved}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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
function initialize(address rootToken_, string name_, string symbol_) external nonpayable
```



*Sets the values for {rootToken}, {name}, and {symbol}. All these values are immutable: they can only be set once during initialization.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken_ | address | undefined |
| name_ | string | undefined |
| symbol_ | string | undefined |

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
function isApprovedForAll(address owner, address operator) external view returns (bool)
```



*See {IERC721-isApprovedForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### mint

```solidity
function mint(address account, uint256 tokenId) external nonpayable returns (bool)
```

Mints an NFT token to a particular address

*Can only be called by the predicate address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | Account of the user to mint the tokens to |
| tokenId | uint256 | Index of NFT to mint to the account |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is succesful |

### mintBatch

```solidity
function mintBatch(address[] accounts, uint256[] tokenIds) external nonpayable returns (bool)
```

Mints multiple NFTs in one transaction

*address and tokenId arrays must match in length*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | Array of addresses to mint each NFT to |
| tokenIds | uint256[] | Array of NFT indexes to mint |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if function call is successful |

### name

```solidity
function name() external view returns (string)
```



*See {IERC721Metadata-name}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address)
```



*See {IERC721-ownerOf}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external nonpayable
```



*See {IERC721-safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external nonpayable
```



*See {IERC721-safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*See {IERC721-setApprovalForAll}.*

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

### symbol

```solidity
function symbol() external view returns (string)
```



*See {IERC721Metadata-symbol}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### tokenURI

```solidity
function tokenURI(uint256 tokenId) external view returns (string)
```



*See {IERC721Metadata-tokenURI}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) external nonpayable
```



*See {IERC721-transferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |



## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
```



*Emitted when `owner` enables `approved` to manage the `tokenId` token.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| approved `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
```



*Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
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

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
```



*Emitted when `tokenId` token is transferred from `from` to `to`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |



