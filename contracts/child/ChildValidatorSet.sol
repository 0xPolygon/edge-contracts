// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../common/Owned.sol";
import "./System.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "../libs/SafeMathInt.sol";
import "../libs/ValidatorStorage.sol";
import "../libs/ValidatorQueue.sol";
import "../libs/WithdrawalQueue.sol";
import "../interfaces/IBLS.sol";
import "../interfaces/IChildValidatorSet.sol";

// solhint-disable max-states-count
contract ChildValidatorSet is System, Owned, ReentrancyGuardUpgradeable, IChildValidatorSet {
    using ArraysUpgradeable for uint256[];
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;
    using WithdrawalQueueLib for WithdrawalQueue;
    using RewardPoolLib for RewardPool;

    bytes32 public constant NEW_VALIDATOR_SIG = 0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc;
    uint256 public constant SPRINT = 64;
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100; // might want to change later!
    uint256 public constant MAX_VALIDATOR_SET_SIZE = 500;
    uint256 public constant REWARD_PRECISION = 10**18;
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;
    // more granular commission?
    uint256 public constant MAX_COMMISSION = 100;

    uint256 public currentEpochId;
    uint256[] public epochEndBlocks;
    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;

    IBLS public bls;
    /**
     * @notice Message to sign for registration
     */
    uint256[2] public message;

    ValidatorTree private _validators;
    ValidatorQueue private _queue;
    mapping(address => WithdrawalQueue) private _withdrawals;

    mapping(uint256 => Epoch) public epochs;
    mapping(address => bool) public whitelist;

    modifier onlyValidator() {
        if (!getValidator(msg.sender).active) revert Unauthorized("VALIDATOR");
        _;
    }

    /**
     * @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
     * @dev only callable by client, can only be called once
     * @param newEpochReward reward for a proposed epoch
     * @param newMinStake minimum stake to become a validator
     * @param newMinDelegation minimum amount to delegate to a validator
     * @param validatorAddresses addresses of initial validators
     * @param validatorPubkeys uint256[4] BLS public keys of initial validators
     * @param validatorStakes amount staked per initial validator
     * @param newBls address pf BLS contract/precompile
     * @param newMessage message for BLS signing
     * @param governance Governance address to set as owner of the contract
     */
    function initialize(
        uint256 newEpochReward,
        uint256 newMinStake,
        uint256 newMinDelegation,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys,
        uint256[] calldata validatorStakes,
        IBLS newBls,
        uint256[2] calldata newMessage,
        address governance
    ) external initializer onlySystemCall {
        currentEpochId = 1;

        _transferOwnership(governance);
        __ReentrancyGuard_init();

        // slither-disable-next-line events-maths
        epochReward = newEpochReward;
        minStake = newMinStake;
        minDelegation = newMinDelegation;

        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            _addToWhitelist(validatorAddresses[i]);
            Validator memory validator = Validator({
                blsKey: validatorPubkeys[i],
                stake: validatorStakes[i],
                totalStake: validatorStakes[i],
                commission: 0,
                withdrawableRewards: 0,
                active: true
            });
            _validators.insert(validatorAddresses[i], validator);
        }
        bls = newBls;
        message = newMessage;
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function commitEpoch(
        uint256 id,
        Epoch calldata epoch,
        Uptime calldata uptime
    ) external onlySystemCall {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(epoch.endBlock > epoch.startBlock, "NO_BLOCKS_COMMITTED");
        require((epoch.endBlock - epoch.startBlock + 1) % SPRINT == 0, "EPOCH_MUST_BE_DIVISIBLE_BY_64");
        require(epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock, "INVALID_START_BLOCK");

        Epoch storage newEpoch = epochs[newEpochId];
        newEpoch.endBlock = epoch.endBlock;
        newEpoch.startBlock = epoch.startBlock;
        newEpoch.epochRoot = epoch.epochRoot;

        epochEndBlocks.push(epoch.endBlock);

        _distributeRewards(uptime);
        _processQueue();

        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function addToWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _addToWhitelist(whitelistAddreses[i]);
        }
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function removeFromWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _removeFromWhitelist(whitelistAddreses[i]);
        }
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external {
        if (!whitelist[msg.sender]) revert Unauthorized("WHITELIST");

        (bool result, bool callSuccess) = bls.verifySingle(signature, pubkey, message);
        require(callSuccess && result, "INVALID_SIGNATURE");

        _validators.insert(
            msg.sender,
            Validator({blsKey: pubkey, stake: 0, totalStake: 0, commission: 0, withdrawableRewards: 0, active: true})
        );
        _removeFromWhitelist(msg.sender);

        emit NewValidator(msg.sender, pubkey);
    }

    // TODO: claim validator rewards before stake or unstake action
    /**
     * @inheritdoc IChildValidatorSet
     */
    function stake() external payable onlyValidator {
        uint256 currentStake = _validators.stakeOf(msg.sender);
        if (msg.value + currentStake < minStake) revert StakeRequirement({src: "stake", msg: "STAKE_TOO_LOW"});
        claimValidatorReward();
        _queue.insert(msg.sender, int256(msg.value), 0);
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function unstake(uint256 amount) external {
        // TODO: check if balance requirement is sufficient for access control
        int256 totalValidatorStake = int256(_validators.stakeOf(msg.sender)) + _queue.pendingStake(msg.sender);
        int256 amountInt = amount.toInt256Safe();
        if (amountInt > totalValidatorStake) revert StakeRequirement({src: "unstake", msg: "INSUFFICIENT_BALANCE"});

        int256 amountAfterUnstake = totalValidatorStake - amountInt;
        if (amountAfterUnstake < int256(minStake) && amountAfterUnstake != 0)
            revert StakeRequirement({src: "unstake", msg: "STAKE_TOO_LOW"});

        claimValidatorReward();
        _queue.insert(msg.sender, amountInt * -1, 0);
        if (amountAfterUnstake == 0) {
            _validators.get(msg.sender).active = false;
        }
        _registerWithdrawal(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function delegate(address validator, bool restake) external payable {
        RewardPool storage delegation = _validators.getDelegationPool(validator);
        if (delegation.balanceOf(msg.sender) + msg.value < minDelegation)
            revert StakeRequirement({src: "delegate", msg: "DELEGATION_TOO_LOW"});
        claimDelegatorReward(validator, restake);
        _delegate(msg.sender, validator, msg.value);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function undelegate(address validator, uint256 amount) external {
        // TODO: check if balance requirement is sufficient for access control
        // Stake storage delegation = delegations[msg.sender][validator];
        RewardPool storage delegation = _validators.getDelegationPool(validator);
        uint256 delegatedAmount = delegation.balanceOf(msg.sender);

        if (amount > delegatedAmount) revert StakeRequirement({src: "undelegate", msg: "INSUFFICIENT_BALANCE"});
        delegation.withdraw(msg.sender, amount);

        uint256 amountAfterUndelegate = delegatedAmount - amount;

        if (amountAfterUndelegate < minDelegation && amountAfterUndelegate != 0)
            revert StakeRequirement({src: "undelegate", msg: "DELEGATION_TOO_LOW"});

        claimDelegatorReward(validator, false);

        int256 amountInt = amount.toInt256Safe();

        _queue.insert(validator, 0, amountInt * -1);
        // delegation.amount -= amount;

        _registerWithdrawal(msg.sender, amount);
        emit Undelegated(msg.sender, validator, amount);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function claimValidatorReward() public {
        // TODO: validator should be able to claim reward even in non-active state
        // check if balance requirement is sufficient for access control
        Validator storage validator = _validators.get(msg.sender);
        uint256 reward = validator.withdrawableRewards;
        if (reward == 0) return;
        validator.withdrawableRewards = 0;
        _registerWithdrawal(msg.sender, reward);
        emit ValidatorRewardClaimed(msg.sender, reward);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function claimDelegatorReward(address validator, bool restake) public {
        RewardPool storage pool = _validators.getDelegationPool(validator);
        uint256 reward = pool.claimRewards(msg.sender);
        if (reward == 0) return;

        if (restake) {
            _delegate(msg.sender, validator, reward);
        } else {
            _registerWithdrawal(msg.sender, reward);
        }

        emit DelegatorRewardClaimed(msg.sender, validator, restake, reward);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function withdraw(address to) external nonReentrant {
        assert(to != address(0));
        WithdrawalQueue storage queue = _withdrawals[msg.sender];
        (uint256 amount, uint256 newHead) = queue.withdrawable(currentEpochId);
        queue.head = newHead;
        emit Withdrawal(msg.sender, to, amount);
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        require(success, "WITHDRAWAL_FAILED");
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function setCommission(uint256 newCommission) external onlyValidator {
        require(newCommission <= MAX_COMMISSION, "INVALID_COMMISSION");
        Validator storage validator = _validators.get(msg.sender);
        validator.commission = newCommission;
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function getCurrentValidatorSet() external view returns (address[] memory) {
        return sortedValidators(ACTIVE_VALIDATOR_SET_SIZE);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory) {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        return epochs[ret + 1];
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function getValidator(address validator) public view returns (Validator memory) {
        return _validators.get(validator);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function delegationOf(address validator, address delegator) external view returns (uint256) {
        return _validators.getDelegationPool(validator).balanceOf(delegator);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function sortedValidators(uint256 n) public view returns (address[] memory) {
        uint256 length = n <= _validators.count ? n : _validators.count;
        address[] memory validatorAddresses = new address[](length);

        if (length == 0) return validatorAddresses;

        address tmpValidator = _validators.last();
        validatorAddresses[0] = tmpValidator;

        for (uint256 i = 1; i < length; i++) {
            tmpValidator = _validators.prev(tmpValidator);
            validatorAddresses[i] = tmpValidator;
        }

        return validatorAddresses;
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function totalStake() external view returns (uint256) {
        return _validators.totalStake;
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function totalActiveStake() public view returns (uint256 activeStake) {
        uint256 length = ACTIVE_VALIDATOR_SET_SIZE <= _validators.count ? ACTIVE_VALIDATOR_SET_SIZE : _validators.count;
        if (length == 0) return 0;

        address tmpValidator = _validators.last();
        activeStake += getValidator(tmpValidator).totalStake;

        for (uint256 i = 1; i < length; i++) {
            tmpValidator = _validators.prev(tmpValidator);
            activeStake += getValidator(tmpValidator).totalStake;
        }
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function withdrawable(address account) external view returns (uint256 amount) {
        (amount, ) = _withdrawals[account].withdrawable(currentEpochId);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function pendingWithdrawals(address account) external view returns (uint256) {
        return _withdrawals[account].pending(currentEpochId);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function getDelegatorReward(address validator, address delegator) external view returns (uint256) {
        return _validators.getDelegationPool(validator).claimableRewards(delegator);
    }

    /**
     * @inheritdoc IChildValidatorSet
     */
    function getValidatorReward(address validator) external view returns (uint256) {
        return getValidator(validator).withdrawableRewards;
    }

    function _distributeRewards(Uptime calldata uptime) private {
        require(uptime.epochId == currentEpochId - 1, "EPOCH_NOT_COMMITTED");

        uint256 length = uptime.uptimeData.length;

        require(length <= ACTIVE_VALIDATOR_SET_SIZE && length <= _validators.count, "INVALID_LENGTH");

        uint256 activeStake = totalActiveStake();
        uint256 reward = epochReward;

        for (uint256 i = 0; i < length; ++i) {
            UptimeData memory uptimeData = uptime.uptimeData[i];
            Validator storage validator = _validators.get(uptimeData.validator);
            uint256 validatorReward = (reward * validator.totalStake * uptimeData.signedBlocks) /
                (activeStake * uptime.totalBlocks);
            (uint256 validatorShares, uint256 delegatorShares) = _calculateValidatorAndDelegatorShares(
                uptimeData.validator,
                validatorReward
            );
            validator.withdrawableRewards += validatorShares;
            emit ValidatorRewardDistributed(uptimeData.validator, validatorReward);
            _validators.getDelegationPool(uptimeData.validator).distributeReward(delegatorShares);
            emit DelegatorRewardDistributed(uptimeData.validator, delegatorShares);
        }
    }

    function _processQueue() private {
        QueuedValidator[] storage queue = _queue.get();
        for (uint256 i = 0; i < queue.length; ++i) {
            QueuedValidator memory item = queue[i];
            address validatorAddr = item.validator;
            // values will be zero for non existing validators
            Validator storage validator = _validators.get(validatorAddr);
            // if validator already present in tree, remove andreinsert to maintain sort
            // TODO move reinsertion logic to library
            if (_validators.exists(validatorAddr)) {
                _validators.remove(validatorAddr);
            }
            validator.stake = (int256(validator.stake) + item.stake).toUint256Safe();
            validator.totalStake = (int256(validator.totalStake) + item.stake + item.delegation).toUint256Safe();
            _validators.insert(validatorAddr, validator);
            _queue.resetIndex(validatorAddr);
        }
        _queue.reset();
    }

    function _registerWithdrawal(address account, uint256 amount) private {
        _withdrawals[account].append(amount, currentEpochId + WITHDRAWAL_WAIT_PERIOD);
        emit WithdrawalRegistered(account, amount);
    }

    function _delegate(
        address delegator,
        address validator,
        uint256 amount
    ) private {
        if (!getValidator(validator).active) revert Unauthorized("INVALID_VALIDATOR");
        _queue.insert(validator, 0, amount.toInt256Safe());
        _validators.getDelegationPool(validator).deposit(delegator, amount);
        // delegations[delegator][validator].amount += amount;
        emit Delegated(delegator, validator, amount);
    }

    function _addToWhitelist(address account) private {
        whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    function _removeFromWhitelist(address account) private {
        whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }

    function _calculateValidatorAndDelegatorShares(address validatorAddr, uint256 totalReward)
        private
        view
        returns (uint256, uint256)
    {
        Validator memory validator = getValidator(validatorAddr);
        uint256 stakedAmount = validator.stake;
        uint256 delegations = _validators.getDelegationPool(validatorAddr).supply;

        if (stakedAmount == 0) return (0, 0);
        if (delegations == 0) return (totalReward, 0);

        uint256 validatorReward = (totalReward * stakedAmount) / (stakedAmount + delegations);
        uint256 delegatorReward = totalReward - validatorReward;

        uint256 commission = (validator.commission * delegatorReward) / 100;

        return (validatorReward + commission, delegatorReward - commission);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
