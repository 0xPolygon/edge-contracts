//SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../lib/EIP712MetaTransaction.sol";
import "../interfaces/child/IChildERC1155.sol";

/**
    @title ChildERC1155
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Child token template for ChildERC1155 predicate deployments
    @dev All child tokens are clones of this contract. Burning and minting is controlled by respective predicates only.
 */
contract ChildERC1155 is EIP712MetaTransaction, ERC1155Upgradeable, IChildERC1155 {
    using StringsUpgradeable for address;
    address private _predicate;
    address private _rootToken;

    modifier onlyPredicate() {
        require(msg.sender == _predicate, "ChildERC1155: Only predicate can call");
        _;
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function initialize(address rootToken_, string calldata uri_) external initializer {
        require(rootToken_ != address(0), "ChildERC1155: BAD_INITIALIZATION");
        _rootToken = rootToken_;
        _predicate = msg.sender;
        __ERC1155_init(uri_);
        _initializeEIP712(string.concat("ChildERC1155-", rootToken_.toHexString()), "1");
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function predicate() external view virtual returns (address) {
        return _predicate;
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function rootToken() external view virtual returns (address) {
        return _rootToken;
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function mint(address account, uint256 id, uint256 amount) external onlyPredicate returns (bool) {
        _mint(account, id, amount, "");

        return true;
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function mintBatch(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyPredicate returns (bool) {
        uint256 length = accounts.length;
        require(length == tokenIds.length && length == amounts.length, "ChildERC1155: array len mismatch");
        for (uint256 i = 0; i < length; ) {
            _mint(accounts[i], tokenIds[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function burn(address from, uint256 id, uint256 amount) external onlyPredicate returns (bool) {
        _burn(from, id, amount);

        return true;
    }

    /**
     * @inheritdoc IChildERC1155
     */
    function burnBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyPredicate returns (bool) {
        _burnBatch(from, tokenIds, amounts);

        return true;
    }

    function _msgSender() internal view virtual override(EIP712MetaTransaction, ContextUpgradeable) returns (address) {
        return EIP712MetaTransaction._msgSender();
    }
}
