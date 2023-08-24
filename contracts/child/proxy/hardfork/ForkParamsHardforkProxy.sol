// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/hardfork/HPCore.sol";
import {ForkParams} from "contracts/child/ForkParams.sol";

/// @notice ForkParams-specific proxy for hardfork migration
/// @dev If starting fresh, use StandardProxy instead
contract ForkParamsHardforkProxy is HPCore {
    function setUpProxy(address logic, address admin) external {
        _setUpProxy(logic, admin); //

        ForkParams forkParams = ForkParams(address(this));
        forkParams.initialize(forkParams.owner());
    }
}
