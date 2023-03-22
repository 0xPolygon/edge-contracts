// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

/**
 * @dev Interface of IChildERC1155
 */
interface IChildERC1155 is IERC1155MetadataURIUpgradeable {
    /**
     * @dev Sets the value for {rootToken} and {uri_}
     *
     * This value is immutable: it can only be set once during
     * initialization.
     */
    function initialize(address rootToken_, string calldata uri_) external;

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function predicate() external view returns (address);

    /**
     * @notice Returns address of the token on the root chain
     * @return address Returns the address of the predicate
     */
    function rootToken() external view returns (address);

    /**
     * @notice Mints an NFT token to a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to mint the tokens to
     * @param id Index of NFT to mint to the account
     * @param amount Amount of NFT to mint
     * @return bool Returns true if function call is succesful
     */
    function mint(address account, uint256 id, uint256 amount) external returns (bool);

    /**
     * @notice Mints multiple NFTs to one address
     * @dev single destination for compliance with the general format of EIP-1155
     * @param accounts Array of addresses to mint each NFT to
     * @param tokenIds Array of indexes of the NFTs to be minted
     * @param amounts Array of the amount of each NFT to be minted
     * @return bool Returns true if function call is successful
     */
    function mintBatch(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external returns (bool);

    /**
     * @notice Burns an NFT tokens from a particular address
     * @dev Can only be called by the predicate address
     * @param from Address to burn the NFTs from
     * @param id Index of NFT to burn from the account
     * @param amount Amount of NFT to burn
     * @return bool Returns true if function call is succesful
     */
    function burn(address from, uint256 id, uint256 amount) external returns (bool);

    /**
     * @notice Burns multiple NFTs from one address
     * @dev included for compliance with the general format of EIP-1155
     * @param from Address to burn NFTs from
     * @param tokenIds Array of indexes of the NFTs to be minted
     * @param amounts Array of the amount of each NFT to be minted
     * @return bool Returns true if function call is successful
     */
    function burnBatch(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (bool);
}
