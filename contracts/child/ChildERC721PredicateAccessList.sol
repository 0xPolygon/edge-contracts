// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ChildERC721Predicate} from "./ChildERC721Predicate.sol";
import {AccessList} from "../lib/AccessList.sol";

/**
    @title ChildERC721PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables ERC721 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC721PredicateAccessList is AccessList, ChildERC721Predicate {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) public virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newRootERC721Predicate, newChildTokenTemplate);
        _initializeAccessList(newUseAllowList, newUseBlockList);
        _transferOwnership(newOwner);
    }

    function _beforeTokenWithdraw() internal virtual override {
        _checkAccessList();
    }
}
