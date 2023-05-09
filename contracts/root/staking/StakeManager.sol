// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../lib/ChildManagerLib.sol";
import "../../lib/StakeManagerLib.sol";

contract StakeManager is IStakeManager, Initializable {
    using ChildManagerLib for ChildChains;
    using StakeManagerLib for Stakes;
    using SafeERC20 for IERC20;

    IERC20 internal matic;
    ChildChains private _chains;
    Stakes private _stakes;

    function initialize(address newMatic) public initializer {
        matic = IERC20(newMatic);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function registerChildChain(address manager) external returns (uint256 id) {
        id = _chains.registerChild(manager);
        ISupernetManager(manager).onInit(id);
        // slither-disable-next-line reentrancy-events
        emit ChildManagerRegistered(id, manager);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeFor(uint256 id, uint256 amount) external {
        require(id != 0 && id <= _chains.counter, "INVALID_ID");
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        matic.safeTransferFrom(msg.sender, address(this), amount);
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        StakeManagerLib.addStake(_stakes, msg.sender, id, amount);
        ISupernetManager manager = managerOf(id);
        manager.onStake(msg.sender, amount);
        // slither-disable-next-line reentrancy-events
        emit StakeAdded(id, msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function releaseStakeOf(address validator, uint256 amount) external {
        uint256 id = idFor(msg.sender);
        _stakes.removeStake(validator, id, amount);
        // slither-disable-next-line reentrancy-events
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
        if (amount > stake) amount = stake;
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
    function totalStakeOfChild(uint256 id) external view returns (uint256 amount) {
        amount = _stakes.totalStakeOfChild(id);
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
        id = ChildManagerLib.idFor(_chains, manager);
    }

    function _withdrawStake(address validator, address to, uint256 amount) private {
        _stakes.withdrawStake(validator, amount);
        // slither-disable-next-line reentrancy-events
        matic.safeTransfer(to, amount);
        emit StakeWithdrawn(validator, to, amount);
    }
}
