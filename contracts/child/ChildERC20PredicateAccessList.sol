// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChildERC20Predicate} from "./ChildERC20Predicate.sol";
import {AccessList} from "../libs/AccessList.sol";

/**
    @title ChildERC20PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables ERC20 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC20PredicateAccessList is ChildERC20Predicate, AccessList {
    function _beforeTokenWithdraw() internal virtual override {
        _checkAccessList();
    }
}
