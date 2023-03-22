// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/StakeManagerLibs.sol";

contract StakeManager is IStakeManager {
    using ChildManager for ChildChains;
    using SafeERC20 for IERC20;
    using StakesManager for Stakes;

    IERC20 private immutable MATIC;
    ChildChains private _chains;
    Stakes private _stakes;

    constructor(address MATIC_) {
        MATIC = IERC20(MATIC_);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function registerChildChain(address manager) external {
        uint256 id = _chains.registerChild(manager);
        ISupernetManager(manager).onInit(id);
        emit ChildManagerRegistered(id, manager);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeFor(uint256 id, uint256 amount, bytes calldata data) external {
        MATIC.safeTransferFrom(msg.sender, address(this), amount);
        _stakes.addStake(msg.sender, id, amount);
        ISupernetManager manager = managerOf(id);
        manager.onStake(msg.sender, amount, data);
        emit StakeAdded(id, msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function releaseStakeOf(address validator, uint256 amount) external {
        uint256 id = idFor(msg.sender);
        _stakes.removeStake(validator, id, amount);
        emit StakeRemoved(id, validator, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawStake(address to, uint256 amount) external {
        _withdrawStake(msg.sender, to, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function slashStakeOf(address validator, uint256 amount) external {
        uint256 id = idFor(msg.sender);
        uint256 stake = stakeOf(validator, id);
        if (amount > stake) revert SlashExceedsStake(id, validator, amount, stake);
        _stakes.removeStake(validator, id, stake);
        _withdrawStake(validator, msg.sender, amount);
        emit StakeRemoved(id, validator, stake);
        emit ValidatorSlashed(id, validator, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawableStake(address validator) external view returns (uint256 amount) {
        amount = _stakes.withdrawableStakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStake() external view returns (uint256 amount) {
        amount = _stakes.totalStake;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStakeOf(address validator) external view returns (uint256 amount) {
        amount = _stakes.totalStakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeOf(address validator, uint256 id) public view returns (uint256 amount) {
        amount = _stakes.stakeOf(validator, id);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function managerOf(uint256 id) public view returns (ISupernetManager manager) {
        manager = ISupernetManager(_chains.managerOf(id));
    }

    /**
     * @inheritdoc IStakeManager
     */
    function idFor(address manager) public view returns (uint256 id) {
        id = _chains.idFor(manager);
    }

    function _withdrawStake(address validator, address to, uint256 amount) private {
        _stakes.withdrawStake(validator, amount);
        MATIC.safeTransfer(to, amount);
        emit StakeWithdrawn(validator, to, amount);
    }
}
