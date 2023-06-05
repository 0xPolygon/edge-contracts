// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RootMintableERC1155Predicate} from "./RootMintableERC1155Predicate.sol";
import {AccessList} from "../lib/AccessList.sol";

/**
    @title RootMintableERC1155PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables child-chain origin ERC1155 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract RootMintableERC1155PredicateAccessList is AccessList, RootMintableERC1155Predicate {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) public virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newChildERC1155Predicate, newChildTokenTemplate);
        _initializeAccessList(newUseAllowList, newUseBlockList);
        _transferOwnership(newOwner);
    }

    function _beforeTokenDeposit() internal virtual override {
        _checkAccessList();
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
