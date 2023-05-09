// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ChildERC1155Predicate} from "./ChildERC1155Predicate.sol";
import {AccessList} from "../lib/AccessList.sol";

/**
    @title ChildERC1155PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables ERC1155 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC1155PredicateAccessList is AccessList, ChildERC1155Predicate {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC1155Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) public virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newRootERC1155Predicate, newChildTokenTemplate);
        _initializeAccessList(newUseAllowList, newUseBlockList);
        _transferOwnership(newOwner);
    }

    function _beforeTokenWithdraw() internal virtual override {
        _checkAccessList();
    }
}
