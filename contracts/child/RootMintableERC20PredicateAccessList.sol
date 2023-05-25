// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RootMintableERC20Predicate} from "./RootMintableERC20Predicate.sol";
import {AccessList} from "../lib/AccessList.sol";

/**
    @title RootMintableERC20PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables child-chain origin ERC20 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract RootMintableERC20PredicateAccessList is AccessList, RootMintableERC20Predicate {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) public virtual onlySystemCall initializer returns (address) {
        _initializeAccessList(newUseAllowList, newUseBlockList);
        _transferOwnership(newOwner);
        return _initialize(newL2StateSender, newStateReceiver, newChildERC20Predicate, newChildTokenTemplate);
    }

    function _beforeTokenWithdraw() internal virtual override {
        _checkAccessList();
    }
}
