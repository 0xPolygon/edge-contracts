// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../../interfaces/root/staking/IStakeManager.sol";
import "../../../interfaces/root/staking/ISupernetManager.sol";

contract SupernetManager is ISupernetManager, Initializable {
    IStakeManager internal STAKE_MANAGER;
    uint256 public id;

    modifier onlyStakeManager() {
        require(msg.sender == address(STAKE_MANAGER), "ONLY_STAKE_MANAGER");
        _;
    }

    function initialize(address stakeManager) public initializer {
        STAKE_MANAGER = IStakeManager(stakeManager);
    }

    function onInit(uint256 id_) external onlyStakeManager {
        id = id_;
    }

    function onStake(address validator, uint256 amount) external onlyStakeManager {
        _onStake(validator, amount);
    }

    function _onStake(address validator, uint256 amount) internal virtual {}
}
