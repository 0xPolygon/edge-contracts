// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/hardfork/HFGenesisProxy.sol";
import {ForkParams} from "contracts/child/ForkParams.sol";

/// @notice ForkParams-specific proxy for hardfork migration
/// @dev If starting fresh, use BasicGenesisProxy instead
contract ForkParamsHFGenesisProxy is HFGenesisProxy {
    function setUpProxy(address logic, address admin) external {
        _setUpProxy(logic, admin); //

        ForkParams forkParams = ForkParams(address(this));
        forkParams.initialize(forkParams.owner());
    }
}
