// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../root/staking/SupernetManager.sol";

contract MockSupernetManager is SupernetManager {
    function initialize(address stakeManager) public initializer {
        __SupernetManager_init(stakeManager);
    }

    function _onStake(address validator, uint256 amount) internal override {}
}
