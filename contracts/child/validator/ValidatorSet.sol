// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../lib/WithdrawalQueue.sol";
import "../../interfaces/child/validator/IValidatorSet.sol";
import "../../interfaces/IStateSender.sol";
import "../System.sol";

contract ValidatorSet is IValidatorSet, ERC20SnapshotUpgradeable, System {
    using WithdrawalQueueLib for WithdrawalQueue;

    bytes32 private constant STAKE_SIG = keccak256("STAKE");
    bytes32 private constant UNSTAKE_SIG = keccak256("UNSTAKE");
    bytes32 private constant SLASH_SIG = keccak256("SLASH");
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;

    IStateSender private STATE_SENDER;
    address private STATE_RECEIVER;
    address private ROOT_CHAIN_MANAGER;
    uint256 private _EPOCH_SIZE;

    uint256 public currentEpochId;

    mapping(uint256 => Epoch) public epochs;
    uint256[] public epochEndBlocks;
    mapping(address => WithdrawalQueue) internal _withdrawals;

    function initialize(
        address stateSender,
        address stateReceiver,
        address rootChainManager,
        uint256 epochSize_,
        ValidatorInit[] memory initalValidators
    ) public initializer {
        __ERC20_init("ValidatorSet", "VSET");
        STATE_SENDER = IStateSender(stateSender);
        STATE_RECEIVER = stateReceiver;
        ROOT_CHAIN_MANAGER = rootChainManager;
        _EPOCH_SIZE = epochSize_;
        for (uint256 i = 0; i < initalValidators.length; i++) {
            _stake(initalValidators[i].addr, initalValidators[i].stake);
        }
        currentEpochId = 1;
    }

    /**
     * @inheritdoc IValidatorSet
     */
    function commitEpoch(uint256 id, Epoch calldata epoch) external onlySystemCall {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(epoch.endBlock > epoch.startBlock, "NO_BLOCKS_COMMITTED");
        require((epoch.endBlock - epoch.startBlock + 1) % _EPOCH_SIZE == 0, "EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
        require(epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock, "INVALID_START_BLOCK");
        epochs[newEpochId] = epoch;
        epochEndBlocks.push(epoch.endBlock);
        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    function onStateReceive(uint256 /*counter*/, address sender, bytes calldata data) external override {
        require(msg.sender == STATE_RECEIVER && sender == ROOT_CHAIN_MANAGER, "INVALID_SENDER");
        if (bytes32(data[:32]) == STAKE_SIG) {
            (address validator, uint256 amount) = abi.decode(data[32:], (address, uint256));
            _stake(validator, amount);
        }
    }

    /**
     * @inheritdoc IValidatorSet
     */
    function unstake(uint256 amount) external {
        _burn(msg.sender, amount);
        _registerWithdrawal(msg.sender, amount);
    }

    /**
     * @inheritdoc IValidatorSet
     */
    function withdraw() external {
        WithdrawalQueue storage queue = _withdrawals[msg.sender];
        (uint256 amount, uint256 newHead) = queue.withdrawable(currentEpochId);
        queue.head = newHead;
        emit Withdrawal(msg.sender, msg.sender, amount);
        STATE_SENDER.syncState(ROOT_CHAIN_MANAGER, abi.encode(UNSTAKE_SIG, msg.sender, amount));
    }

    /**
     * @inheritdoc IValidatorSet
     */
    function withdrawable(address account) external view returns (uint256 amount) {
        (amount, ) = _withdrawals[account].withdrawable(currentEpochId);
    }

    /**
     * @inheritdoc IValidatorSet
     */
    function pendingWithdrawals(address account) external view returns (uint256) {
        return _withdrawals[account].pending(currentEpochId);
    }

    /**
     * @inheritdoc IValidatorSet
     */
    function totalBlocks(uint256 epochId) external view returns (uint256 length) {
        length = epochs[epochId].endBlock - epochs[epochId].startBlock + 1;
    }

    function _registerWithdrawal(address account, uint256 amount) internal {
        _withdrawals[account].append(amount, currentEpochId + WITHDRAWAL_WAIT_PERIOD);
        emit WithdrawalRegistered(account, amount);
    }

    function _slash(address validator) internal {
        // unstake validator
        _burn(validator, balanceOf(validator));
        // remove pending withdrawals
        delete _withdrawals[validator];
        // slash validator
        STATE_SENDER.syncState(ROOT_CHAIN_MANAGER, abi.encode(SLASH_SIG, validator));
    }

    function _stake(address validator, uint256 amount) internal {
        _mint(validator, amount);
    }

    /// @dev the epoch number is also the snapshot id
    function _getCurrentSnapshotId() internal view override returns (uint256) {
        return currentEpochId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || to == address(0), "TRANSFER_FORBIDDEN");
        super._beforeTokenTransfer(from, to, amount);
    }

    function EPOCH_SIZE() external view override returns (uint256) {
        return _EPOCH_SIZE;
    }

    function balanceOfAt(
        address account,
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IValidatorSet) returns (uint256) {
        return super.balanceOfAt(account, epochNumber);
    }

    function totalSupplyAt(
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IValidatorSet) returns (uint256) {
        return super.totalSupplyAt(epochNumber);
    }
}
