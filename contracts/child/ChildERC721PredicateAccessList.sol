// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChildERC721Predicate} from "./ChildERC721Predicate.sol";
import {AccessList} from "../libs/AccessList.sol";

/**
    @title ChildERC721PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables ERC721 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC721PredicateAccessList is ChildERC721Predicate, AccessList {
    function _beforeTokenWithdraw() internal virtual override {
        _checkAccessList();
    }
}
