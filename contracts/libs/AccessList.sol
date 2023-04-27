// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAddressList} from "../interfaces/IAddressList.sol";
import {System} from "../child/System.sol";

/**
    @title AccessList
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Checks the access lists to see if an address is allowed and not blocked
 */
contract AccessList is System {
    bool private useAllowList;
    bool private useBlockList;

    event AllowListUsageSet(uint256 timestamp, bool status);
    event BlockListUsageSet(uint256 timestamp, bool status);

    function setAllowList(bool _useAllowList) external {
        if (_useAllowList != useAllowList) {
            useAllowList = _useAllowList;
            emit AllowListUsageSet(block.timestamp, _useAllowList);
        }
    }

    function setBlockList(bool _useBlockList) external {
        if (_useBlockList != useBlockList) {
            useBlockList = _useBlockList;
            emit BlockListUsageSet(block.timestamp, _useBlockList);
        }
    }

    function _checkAccessList() internal view {
        if (useAllowList) {
            // solhint-disable avoid-low-level-calls
            (bool allowSuccess, bytes memory allowlistRes) = ALLOWLIST_PRECOMPILE.staticcall{gas: READ_ADDRESSLIST_GAS}(
                abi.encodeWithSelector(IAddressList.readAddressList.selector, msg.sender)
            );
            require(allowSuccess && abi.decode(allowlistRes, (uint256)) > 0, "DISALLOWED_SENDER");
        }
        if (useBlockList) {
            (bool blockSuccess, bytes memory blocklistRes) = BLOCKLIST_PRECOMPILE.staticcall{gas: READ_ADDRESSLIST_GAS}(
                abi.encodeWithSelector(IAddressList.readAddressList.selector, msg.sender)
            );
            require(blockSuccess && abi.decode(blocklistRes, (uint256)) > 0, "BLOCKED_SENDER");
        }
    }
}
