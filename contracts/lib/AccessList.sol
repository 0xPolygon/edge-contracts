// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IAddressList} from "../interfaces/IAddressList.sol";
import {System} from "../child/System.sol";

/**
    @title AccessList
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Checks the access lists to see if an address is allowed and not blocked
 */
contract AccessList is Ownable2StepUpgradeable, System {
    bool private _useAllowList;
    bool private _useBlockList;

    event AllowListUsageSet(uint256 indexed block, bool indexed status);
    event BlockListUsageSet(uint256 indexed block, bool indexed status);

    function setAllowList(bool newUseAllowList) external onlyOwner {
        _useAllowList = newUseAllowList;
        emit AllowListUsageSet(block.number, newUseAllowList);
    }

    function setBlockList(bool newUseBlockList) external onlyOwner {
        _useBlockList = newUseBlockList;
        emit BlockListUsageSet(block.number, newUseBlockList);
    }

    function _checkAccessList() internal view {
        if (_useAllowList) {
            // solhint-disable avoid-low-level-calls
            // slither-disable-next-line low-level-calls
            (bool allowSuccess, bytes memory allowlistRes) = ALLOWLIST_PRECOMPILE.staticcall{gas: READ_ADDRESSLIST_GAS}(
                abi.encodeWithSelector(IAddressList.readAddressList.selector, msg.sender)
            );
            require(allowSuccess && abi.decode(allowlistRes, (uint256)) > 0, "DISALLOWED_SENDER");
        }
        if (_useBlockList) {
            // slither-disable-next-line low-level-calls
            (bool blockSuccess, bytes memory blocklistRes) = BLOCKLIST_PRECOMPILE.staticcall{gas: READ_ADDRESSLIST_GAS}(
                abi.encodeWithSelector(IAddressList.readAddressList.selector, msg.sender)
            );
            require(blockSuccess && abi.decode(blocklistRes, (uint256)) != 1, "BLOCKED_SENDER");
        }
    }

    function _initializeAccessList(bool __useAllowList, bool __useBlockList) internal {
        _useAllowList = __useAllowList;
        _useBlockList = __useBlockList;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
