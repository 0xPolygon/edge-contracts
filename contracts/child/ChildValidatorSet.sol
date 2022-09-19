// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ChildValidatorSet/CVSStorage.sol";
import "./ChildValidatorSet/CVSAccessControl.sol";
import "./ChildValidatorSet/CVSWithdrawal.sol";
import "./ChildValidatorSet/CVSStaking.sol";
import "./System.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "../libs/SafeMathInt.sol";
import "../interfaces/IChildValidatorSet.sol";

// solhint-disable max-states-count
contract ChildValidatorSet is IChildValidatorSet, System, CVSStorage, CVSAccessControl, CVSWithdrawal, CVSStaking {
    using ArraysUpgradeable for uint256[];
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;
    using RewardPoolLib for RewardPool;

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
    function delegationOf(address validator, address delegator) external view returns (uint256) {
        return _validators.getDelegationPool(validator).balanceOf(delegator);
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
    function getDelegatorReward(address validator, address delegator) external view returns (uint256) {
        return _validators.getDelegationPool(validator).claimableRewards(delegator);
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
            _distributeValidatorReward(uptimeData.validator, validatorShares);
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
}
