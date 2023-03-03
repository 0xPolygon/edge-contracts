// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

/**
 * @dev Interface of IChildERC1155
 */
interface IChildERC1155 is IERC1155MetadataURIUpgradeable {
    /**
     * @dev Sets the value for {rootToken}.
     *
     * This value is immutable: it can only be set once during
     * initialization.
     */
    function initialize(address rootToken_) external;

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function predicate() external view returns (address);

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function rootToken() external view returns (address);

    /**
     * @notice Mints an NFT token to a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to mint the tokens to
     * @param tokenId Index of NFT to mint to the account
     * @param amount Amount of NFT to mint
     * @return bool Returns true if function call is succesful
     */
    function mint(address account, uint256 tokenId, uint256 amount) external returns (bool);

    /**
     * @notice Burns an NFT tokens from a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to burn the tokens from
     * @param tokenId Index of NFT to burn from the account
     * @param amount Amount of NFT to burn
     * @return bool Returns true if function call is succesful
     */
    function burn(address account, uint256 tokenId, uint256 amount) external returns (bool);
}
