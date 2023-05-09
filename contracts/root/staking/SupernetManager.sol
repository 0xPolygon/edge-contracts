// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/root/staking/IStakeManager.sol";
import "../../interfaces/root/staking/ISupernetManager.sol";

abstract contract SupernetManager is ISupernetManager, Initializable {
    IStakeManager internal stakeManager;
    uint256 public id;

    modifier onlyStakeManager() {
        require(msg.sender == address(stakeManager), "ONLY_STAKE_MANAGER");
        _;
    }

    // slither-disable-next-line naming-convention
    function __SupernetManager_init(address newStakeManager) internal onlyInitializing {
        stakeManager = IStakeManager(newStakeManager);
    }

    function onInit(uint256 id_) external onlyStakeManager {
        // slither-disable-next-line events-maths
        id = id_;
    }

    function onStake(address validator, uint256 amount) external onlyStakeManager {
        _onStake(validator, amount);
    }

    function _onStake(address validator, uint256 amount) internal virtual;
}
