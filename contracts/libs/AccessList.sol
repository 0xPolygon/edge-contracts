// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IAddressList} from "../interfaces/IAddressList.sol";
import {System} from "../child/System.sol";

/**
    @title AccessList
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Checks the access lists to see if an address is allowed and not blocked
 */
contract AccessList is Ownable2StepUpgradeable, System {
    bool private useAllowList = true;
    bool private useBlockList = true;

    event AllowListUsageSet(uint256 indexed block, bool indexed status);
    event BlockListUsageSet(uint256 indexed block, bool indexed status);

    function setAllowList(bool _useAllowList) external onlyOwner {
        useAllowList = _useAllowList;
        emit AllowListUsageSet(block.number, _useAllowList);
    }

    function setBlockList(bool _useBlockList) external onlyOwner {
        useBlockList = _useBlockList;
        emit BlockListUsageSet(block.number, _useBlockList);
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
