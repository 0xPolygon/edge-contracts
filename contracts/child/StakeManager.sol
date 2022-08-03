// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./System.sol";
import "../libs/ValidatorStorage.sol";
import "../libs/ValidatorQueue.sol";
import "../libs/WithdrawalQueue.sol";
import "../common/Owned.sol";

import "hardhat/console.sol";

error StakeRequirement(string src, string msg);

interface IChildValidatorSet {
    struct Validator {
        address _address;
        //uint256[4] blsKey; // default mapping function does not return array
        uint256 selfStake;
        uint256 totalStake; // self-stake + delegation
        uint256 commission;
        ValidatorStatus status;
    }

    enum ValidatorStatus {
        REGISTERED, // 0 -> will be staked next epock
        STAKED, // 1 -> currently staked (i.e. validating)
        UNSTAKING, // 2 -> currently unstaking (i.e. will stop validating)
        UNSTAKED // 3 -> not staked (i.e. is not validating)
    }

    struct Epoch {
        uint256 startBlock;
        uint256 endBlock;
        bytes32 epochRoot;
        uint256[] validatorSet;
    }

    // solhint-disable-next-line
    function ACTIVE_VALIDATOR_SET_SIZE() external returns (uint256);

    function addSelfStake(uint256 id, uint256 amount) external;

    function unstake(uint256 id, uint256 amount) external;

    function addTotalStake(uint256 id, uint256 amount) external;

    function updateValidatorStatus(uint256 id, ValidatorStatus newStatus) external;

    function validatorIdByAddress(address _address) external view returns (uint256);

    function currentEpochId() external view returns (uint256);

    function currentValidatorId() external view returns (uint256);

    function activeValidatorSetSize() external view returns (uint256);

    function getValidatorStatus(uint256 id) external view returns (ValidatorStatus);

    function calculateValidatorPower(uint256 id) external view returns (uint256);

    function validators(uint256 id) external view returns (Validator memory);

    function epochs(uint256 id) external view returns (Epoch memory);
}

// TODO events
contract StakeManager is Owned, System, ReentrancyGuardUpgradeable {
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;
    using WithdrawalQueueLib for WithdrawalQueue;

    struct Uptime {
        uint256 epochId;
        uint256[] uptimes;
        uint256 totalUptime;
    }

    struct Stake {
        uint256 epochId;
        uint256 amount;
    }

    uint256 public constant REWARD_PRECISION = 10**18;
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;

    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;
    IChildValidatorSet public childValidatorSet;
    ValidatorTree private _validators;
    ValidatorQueue private _queue;
    mapping(address => WithdrawalQueue) private _withdrawals;

    mapping(address => mapping(uint256 => uint256)) public totalRewards; // validator address -> epoch -> amount
    mapping(uint256 => mapping(address => uint256)) public validatorRewardShares; // epoch -> validator address -> amount
    mapping(uint256 => mapping(address => uint256)) public delegatorRewardShares; // epoch -> validator address -> reward per share
    mapping(address => mapping(address => Stake)) public delegations; // user address -> validator address -> Delegation
    mapping(address => Stake) public selfStakes; // validator address -> Delegation
    mapping(address => bool) public whitelist;

    modifier onlyValidator() {
        if (!whitelist[msg.sender]) revert Unauthorized("VALIDATOR");
        // require(childValidatorSet.validatorIdByAddress(msg.sender) != 0, "ONLY_VALIDATOR");
        _;
    }

    function initialize(
        uint256 newEpochReward,
        uint256 newMinStake,
        uint256 newMinDelegation,
        IChildValidatorSet newChildValidatorSet,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys,
        uint256[] calldata validatorStakes
    ) external initializer {
        epochReward = newEpochReward;
        minStake = newMinStake;
        minDelegation = newMinDelegation;
        childValidatorSet = newChildValidatorSet;
        __Owned_init();
        __ReentrancyGuard_init();

        // TODO transfer of funds?
        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            _addToWhitelist(validatorAddresses[i]);
            Validator memory data = Validator({
                blsKey: validatorPubkeys[i],
                stake: validatorStakes[i],
                totalStake: validatorStakes[i],
                commission: 0
            });
            _validators.insert(validatorAddresses[i], data);
        }
    }

    /**
     * @notice Adds addresses which are allowed to register as validators.
     * @param whitelistAddreses Array of address to whitelist
     */
    function addToWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _addToWhitelist(whitelistAddreses[i]);
        }
    }

    /**
     * @notice Deletes addresses which are allowed to register as validators.
     * @param whitelistAddreses Array of address to remove from whitelist
     */
    function removeFromWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _removeFromWhitelist(whitelistAddreses[i]);
        }
    }

    function distributeRewards(Uptime calldata uptime) external {
        require(msg.sender == address(childValidatorSet), "ONLY_VALIDATOR_SET");

        require(uptime.epochId == childValidatorSet.currentEpochId() - 1, "EPOCH_NOT_COMMITTED");

        uint256 length = uptime.uptimes.length;

        require(
            length <= childValidatorSet.ACTIVE_VALIDATOR_SET_SIZE() && length < childValidatorSet.currentValidatorId(),
            "INVALID_LENGTH"
        );

        uint256[] memory weights = new uint256[](length);
        uint256 aggPower = 0;
        uint256 aggWeight = 0;

        for (uint256 i = 0; i < length; ++i) {
            IChildValidatorSet.ValidatorStatus status = childValidatorSet.getValidatorStatus(i + 1);
            if (status == IChildValidatorSet.ValidatorStatus.STAKED) {
                uint256 power = childValidatorSet.calculateValidatorPower(i + 1);
                aggPower += power;
                weights[i] = uptime.uptimes[i] * power;
                aggWeight += weights[i];
            } else if (status == IChildValidatorSet.ValidatorStatus.REGISTERED) {
                childValidatorSet.updateValidatorStatus(i + 1, IChildValidatorSet.ValidatorStatus.STAKED);
            } // to-do: other cases
        }

        require(aggPower > (66 * (10**6)), "NOT_ENOUGH_CONSENSUS");

        uint256 reward = epochReward;

        reward = (reward * aggPower) / (100 * (10**6)); // scale reward to power staked

        // for (uint256 i = 0; i < length; ++i) {
        //     uint256 validatorReward = (reward * weights[i]) / aggWeight;
        //     (uint256 validatorShares, uint256 delegatorShares) = _calculateValidatorAndDelegatorShares(
        //         i + 1,
        //         validatorReward
        //     );
        //     validatorRewardShares[uptime.epochId][i + 1] = validatorShares;
        //     delegatorRewardShares[uptime.epochId][i + 1] = delegatorShares;
        // }
    }

    function processQueue() external {
        if (msg.sender != address(childValidatorSet)) revert Unauthorized("VALIDATOR_SET");
        QueuedValidator[] storage queue = _queue.get();
        for (uint256 i = 0; i < queue.length; ++i) {
            QueuedValidator memory item = queue[i];
            address validatorAddr = item.validator;
            // values will be zero for non existing validators
            Validator storage validator = _validators.get(validatorAddr);
            // if validator already present in tree, remove and reinsert to maintain sort
            // TODO move reinsertion logic to library
            if (_validators.exists(validatorAddr)) {
                _validators.remove(validatorAddr);
            }
            validator.stake = uint256(int256(validator.stake) + item.stake);
            validator.totalStake = uint256(int256(validator.totalStake) + item.stake + item.delegation);
            if (validator.stake > 0) {
                _validators.insert(validatorAddr, validator);
            }
            _queue.resetIndex(validatorAddr);
        }
        _queue.reset();
    }

    function stake() external payable onlyValidator {
        uint256 currentStake = _validators.stakeOf(msg.sender);
        if (msg.value + currentStake < minStake) revert StakeRequirement({src: "stake", msg: "STAKE_TOO_LOW"});
        _queue.insert(msg.sender, int256(msg.value), 0);
    }

    function unstake(uint256 amount) external {
        int256 totalStake = int256(_validators.stakeOf(msg.sender)) + _queue.pendingStake(msg.sender);
        int256 amountInt = int256(amount);
        // prevent overflow
        assert(amountInt > 0);
        if (amountInt > totalStake) revert StakeRequirement({src: "unstake", msg: "INSUFFICIENT_BALANCE"});
        int256 amountAfterUnstake = totalStake - amountInt;
        if (amountAfterUnstake < int256(minStake) && amountAfterUnstake != 0)
            revert StakeRequirement({src: "unstake", msg: "STAKE_TOO_LOW"});
        _queue.insert(msg.sender, amountInt * -1, 0);
        if (amountAfterUnstake == 0) {
            _removeFromWhitelist(msg.sender);
        }
        _registerWithdrawal(msg.sender, amount);
    }

    // TODO undelegate
    function delegate(address validator, bool restake) external payable {
        if (!whitelist[validator]) revert Unauthorized("INVALID_VALIDATOR");

        Stake storage delegation = delegations[msg.sender][validator];
        require(delegation.amount + msg.value >= minDelegation, "DELEGATION_TOO_LOW");

        claimDelegatorReward(validator, restake);

        _queue.insert(msg.sender, 0, int256(msg.value));
        delegation.amount += msg.value;
    }

    function claimDelegatorReward(address validator, bool restake) public {
        uint256 reward = calculateDelegatorReward(validator, msg.sender);

        Stake storage delegation = delegations[msg.sender][validator];
        delegation.epochId = childValidatorSet.currentEpochId();
        // update epochId before returning
        if (reward == 0) return;

        if (restake) {
            _queue.insert(msg.sender, 0, int256(reward));
            delegation.amount += reward;
        } else {
            _registerWithdrawal(msg.sender, reward);
        }
    }

    function claimValidatorReward() public onlyValidator {
        // uint256 id = childValidatorSet.validatorIdByAddress(msg.sender);
        uint256 reward = calculateValidatorReward(msg.sender);
        Stake storage delegation = delegations[msg.sender][msg.sender];
        delegation.epochId = childValidatorSet.currentEpochId();
        _registerWithdrawal(msg.sender, reward);
    }

    function getValidator(address validator) public view returns (Validator memory) {
        return _validators.get(validator);
    }

    // get first `n` of validators sorted by stake from high to low
    function sortedValidators(uint256 n) external view returns (address[] memory) {
        uint256 length = n <= _validators.count ? n : _validators.count;
        address[] memory validatorAddresses = new address[](length);

        address tmpValidator = _validators.last();
        validatorAddresses[0] = tmpValidator;

        for (uint256 i = 1; i < length; i++) {
            tmpValidator = _validators.prev(tmpValidator);
            validatorAddresses[i] = tmpValidator;
        }

        return validatorAddresses;
    }

    function withdrawable(address account) public view returns (uint256) {
        return _withdrawals[account].withdrawable(childValidatorSet.currentEpochId());
    }

    function pendingWithdrawals(address account) public view returns (uint256) {
        return _withdrawals[account].pending(childValidatorSet.currentEpochId());
    }

    function calculateDelegatorReward(address validator, address delegator) public view returns (uint256) {
        Stake memory delegation = delegations[delegator][validator];

        uint256 startIndex = delegation.epochId;

        uint256 endIndex = childValidatorSet.currentEpochId() - 1;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * delegatorRewardShares[i][validator];
        }

        return totalReward / REWARD_PRECISION;
    }

    function calculateValidatorReward(address validator) public view returns (uint256) {
        Stake memory delegation = selfStakes[validator];

        uint256 startIndex = delegation.epochId;
        uint256 endIndex = childValidatorSet.currentEpochId() - 1;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * validatorRewardShares[i][validator];
        }

        return totalReward / REWARD_PRECISION;
    }

    function _registerWithdrawal(address account, uint256 amount) internal {
        _withdrawals[account].append(amount, childValidatorSet.currentEpochId() + WITHDRAWAL_WAIT_PERIOD);
    }

    function _calculateValidatorAndDelegatorShares(address validatorAddr, uint256 totalReward)
        internal
        view
        returns (uint256, uint256)
    {
        Validator memory validator = getValidator(validatorAddr);
        // IChildValidatorSet.Validator memory validator = childValidatorSet.validators(validatorId);
        // require(validator._address != address(0), "INVALID_VALIDATOR_ID");

        if (validator.totalStake == 0) {
            return (0, 0);
        }

        uint256 rewardShares = (totalReward * REWARD_PRECISION) / validator.totalStake;

        if ((validator.totalStake - validator.stake) == 0) {
            return (rewardShares, 0);
        }

        uint256 delegatorShares = (totalReward * REWARD_PRECISION) / (validator.totalStake - validator.stake);

        uint256 commission = (validator.commission * delegatorShares) / 100;

        return (rewardShares - commission, delegatorShares - commission);
    }

    function _addToWhitelist(address account) internal {
        whitelist[account] = true;
        // TODO event
    }

    function _removeFromWhitelist(address account) internal {
        whitelist[account] = false;
        // TODO event
    }
}
