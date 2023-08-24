// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/hardfork/ProxyBase.sol";
import {NetworkParams} from "contracts/child/NetworkParams.sol";

/// @notice NetworkParams-specific proxy for hardfork migration
/// @dev If starting fresh, use GenesisProxy instead
contract NetworkParamsHardforkProxy is ProxyBase {
    function setUpProxy(address logic, address admin, NetworkParams.InitParams memory initParams) external {
        _setUpProxy(logic, admin, "");

        // slither-disable-next-line assembly
        assembly {
            sstore(0, 0)
            sstore(1, 0)
            sstore(2, 0)
            sstore(3, 0)
            sstore(4, 0)
        }

        NetworkParams(address(this)).initialize(initParams);
    }
}
