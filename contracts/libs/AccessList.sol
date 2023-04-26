// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAddressList} from "../interfaces/IAddressList.sol";
import {System} from "../child/System.sol";

/**
    @title AccessList
    @author Polygon Technology (@QEDK)
    @notice Checks the access lists to see if an address is allowed and not blocked
 */
contract AccessList is System {
    function _checkAccessList() internal view {
        // solhint-disable avoid-low-level-calls
        (bool allowSuccess, bytes memory allowlistRes) = ALLOWLIST_PRECOMPILE.staticcall{gas: READ_ADDRESSLIST_GAS}(
            abi.encodeWithSelector(IAddressList.readAddressList.selector, msg.sender)
        );
        require(allowSuccess && abi.decode(allowlistRes, (uint256)) > 0, "DISALLOWED_SENDER");
        (bool blockSuccess, bytes memory blocklistRes) = BLOCKLIST_PRECOMPILE.staticcall{gas: READ_ADDRESSLIST_GAS}(
            abi.encodeWithSelector(IAddressList.readAddressList.selector, msg.sender)
        );
        require(blockSuccess && abi.decode(blocklistRes, (uint256)) > 0, "BLOCKED_SENDER");
    }
}
