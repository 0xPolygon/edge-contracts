// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../interfaces/root/staking/IStakeManager.sol";
import "../../../interfaces/root/staking/ISupernetManager.sol";

abstract contract SupernetManager is ISupernetManager {
    IStakeManager internal immutable STAKE_MANAGER;
    uint256 public id;

    modifier onlyStakeManager() {
        require(msg.sender == address(STAKE_MANAGER), "ONLY_STAKE_MANAGER");
        _;
    }

    constructor(address stakeManager) {
        STAKE_MANAGER = IStakeManager(stakeManager);
    }

    function onInit(uint256 id_) external onlyStakeManager {
        id = id_;
    }

    function onStake(address validator, uint256 amount, bytes calldata data) external onlyStakeManager {
        _onStake(validator, amount, data);
    }

    function _onStake(address validator, uint256 amount, bytes calldata data) internal virtual;
}
