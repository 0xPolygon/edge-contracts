// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RootMintableERC721Predicate} from "./RootMintableERC721Predicate.sol";
import {AccessList} from "../lib/AccessList.sol";

/**
    @title RootMintableERC721PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables child-chain origin ERC721 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract RootMintableERC721PredicateAccessList is AccessList, RootMintableERC721Predicate {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC721Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) public virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newChildERC721Predicate, newChildTokenTemplate);
        _initializeAccessList(newUseAllowList, newUseBlockList);
        _transferOwnership(newOwner);
    }

    function _beforeTokenDeposit() internal virtual override {
        _checkAccessList();
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
