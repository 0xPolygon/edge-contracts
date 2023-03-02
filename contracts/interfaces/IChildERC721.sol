// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @dev Interface of IChildERC721
 */
interface IChildERC721 is IERC721MetadataUpgradeable {
    /**
     * @dev Sets the values for {rootToken}, {name}, and {symbol}.
     *
     * All these values are immutable: they can only be set once during
     * initialization.
     */
    function initialize(
        address rootToken_,
        string calldata name_,
        string calldata symbol_
    ) external;

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
     * @return bool Returns true if function call is succesful
     */
    function mint(address account, uint256 tokenId) external returns (bool);

    /**
     * @notice Burns an NFT tokens from a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to burn the tokens from
     * @param tokenId Index of NFT to burn from the account
     * @return bool Returns true if function call is succesful
     */
    function burn(address account, uint256 tokenId) external returns (bool);
}
