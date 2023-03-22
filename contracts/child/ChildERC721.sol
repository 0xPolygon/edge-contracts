//SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../lib/EIP712MetaTransaction.sol";
import "../interfaces/child/IChildERC721.sol";

/**
    @title ChildERC721
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Child token template for ChildERC721 predicate deployments
    @dev All child tokens are clones of this contract. Burning and minting is controlled by respective predicates only.
 */
contract ChildERC721 is EIP712MetaTransaction, ERC721Upgradeable, IChildERC721 {
    address private _predicate;
    address private _rootToken;

    modifier onlyPredicate() {
        require(msg.sender == _predicate, "ChildERC721: Only predicate can call");
        _;
    }

    /**
     * @inheritdoc IChildERC721
     */
    function initialize(address rootToken_, string calldata name_, string calldata symbol_) external initializer {
        require(
            rootToken_ != address(0) && bytes(name_).length != 0 && bytes(symbol_).length != 0,
            "ChildERC721: Bad initialization"
        );
        _rootToken = rootToken_;
        _predicate = msg.sender;
        __ERC721_init(name_, symbol_);
        _initializeEIP712(name_, "1");
    }

    /**
     * @inheritdoc IChildERC721
     */
    function predicate() external view virtual returns (address) {
        return _predicate;
    }

    /**
     * @inheritdoc IChildERC721
     */
    function rootToken() external view virtual returns (address) {
        return _rootToken;
    }

    /**
     * @inheritdoc IChildERC721
     */
    function mint(address account, uint256 tokenId) external onlyPredicate returns (bool) {
        _safeMint(account, tokenId);

        return true;
    }

    /**
     * @inheritdoc IChildERC721
     */
    function mintBatch(address[] calldata accounts, uint256[] calldata tokenIds) external onlyPredicate returns (bool) {
        uint256 length = accounts.length;
        require(length == tokenIds.length, "ChildERC721: Array len mismatch");
        for (uint256 i = 0; i < length; ) {
            _safeMint(accounts[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /**
     * @inheritdoc IChildERC721
     */
    function burn(address account, uint256 tokenId) external onlyPredicate returns (bool) {
        require(account == ownerOf(tokenId), "ChildERC721: Only owner can burn");

        _burn(tokenId);

        return true;
    }

    /**
     * @inheritdoc IChildERC721
     */
    function burnBatch(address account, uint256[] calldata tokenIds) external onlyPredicate returns (bool) {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = tokenIds[i];
            require(account == ownerOf(tokenId), "ChildERC721: Only owner can burn");

            _burn(tokenId);

            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _msgSender() internal view virtual override(EIP712MetaTransaction, ContextUpgradeable) returns (address) {
        return EIP712MetaTransaction._msgSender();
    }
}
