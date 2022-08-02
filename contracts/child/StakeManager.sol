// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Initializable} from "../libs/Initializable.sol";
import {System} from "./System.sol";
import "../libs/ValidatorStorage.sol";
import "../libs/ValidatorQueue.sol";

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

    function updateValidatorStatus(uint256 id, ValidatorStatus newStatus)
        external;

    function validatorIdByAddress(address _address)
        external
        view
        returns (uint256);

    function currentEpochId() external view returns (uint256);

    function currentValidatorId() external view returns (uint256);

    function activeValidatorSetSize() external view returns (uint256);

    function getValidatorStatus(uint256 id)
        external
        view
        returns (ValidatorStatus);

    function calculateValidatorPower(uint256 id)
        external
        view
        returns (uint256);

    function validators(uint256 id) external view returns (Validator memory);

    function epochs(uint256 id) external view returns (Epoch memory);
}

contract StakeManager is System, Initializable, ReentrancyGuard {
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;

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

    uint256 public epochReward;
    uint256 public minSelfStake;
    uint256 public minDelegation;
    IChildValidatorSet public childValidatorSet;
    ValidatorTree private _validators;
    ValidatorQueue private _queue;

    mapping(uint256 => mapping(uint256 => uint256)) public totalRewards; // validator id -> epoch -> amount
    mapping(uint256 => mapping(uint256 => uint256))
        public validatorRewardShares; // epoch -> validator id -> amount
    mapping(uint256 => mapping(uint256 => uint256))
        public delegatorRewardShares; // epoch -> validator id -> reward per share
    mapping(address => mapping(uint256 => Stake)) public delegations; // user address -> validator id -> Delegation
    mapping(uint256 => Stake) public selfStakes; // validator id -> Delegation

    modifier onlyValidator() {
        require(
            childValidatorSet.validatorIdByAddress(msg.sender) != 0,
            "ONLY_VALIDATOR"
        );
        _;
    }

    function initialize(
        uint256 newEpochReward,
        uint256 newMinSelfStake,
        uint256 newMinDelegation,
        IChildValidatorSet newChildValidatorSet
    ) external initializer {
        epochReward = newEpochReward;
        minSelfStake = newMinSelfStake;
        minDelegation = newMinDelegation;
        childValidatorSet = newChildValidatorSet;
    }

    function distributeRewards(Uptime calldata uptime) external {
        require(msg.sender == address(childValidatorSet), "ONLY_VALIDATOR_SET");

        require(
            uptime.epochId == childValidatorSet.currentEpochId() - 1,
            "EPOCH_NOT_COMMITTED"
        );

        uint256 length = uptime.uptimes.length;

        require(
            length <= childValidatorSet.ACTIVE_VALIDATOR_SET_SIZE() &&
                length < childValidatorSet.currentValidatorId(),
            "INVALID_LENGTH"
        );

        uint256[] memory weights = new uint256[](length);
        uint256 aggPower = 0;
        uint256 aggWeight = 0;

        for (uint256 i = 0; i < length; ++i) {
            IChildValidatorSet.ValidatorStatus status = childValidatorSet
                .getValidatorStatus(i + 1);
            if (status == IChildValidatorSet.ValidatorStatus.STAKED) {
                uint256 power = childValidatorSet.calculateValidatorPower(
                    i + 1
                );
                aggPower += power;
                weights[i] = uptime.uptimes[i] * power;
                aggWeight += weights[i];
            } else if (
                status == IChildValidatorSet.ValidatorStatus.REGISTERED
            ) {
                childValidatorSet.updateValidatorStatus(
                    i + 1,
                    IChildValidatorSet.ValidatorStatus.STAKED
                );
            } // to-do: other cases
        }

        require(aggPower > (66 * (10**6)), "NOT_ENOUGH_CONSENSUS");

        uint256 reward = epochReward;

        reward = (reward * aggPower) / (100 * (10**6)); // scale reward to power staked

        for (uint256 i = 0; i < length; ++i) {
            uint256 validatorReward = (reward * weights[i]) / aggWeight;
            (
                uint256 validatorShares,
                uint256 delegatorShares
            ) = _calculateValidatorAndDelegatorShares(i + 1, validatorReward);
            validatorRewardShares[uptime.epochId][i + 1] = validatorShares;
            delegatorRewardShares[uptime.epochId][i + 1] = delegatorShares;
        }
    }

    function processQueue() external {
        require(msg.sender == address(childValidatorSet), "ONLY_VALIDATOR_SET");
        QueuedValidator[] storage queue = _queue.get();
        for (uint256 i = 0; i < queue.length; ++i) {
            QueuedValidator memory item = queue[i];
            address validatorAddr = item.validator;
            Validator storage validator = _validators.get(validatorAddr);
            // values will be zero for non existing validators
            uint256 stakeAmount = validator.stake;
            uint256 totalStakeAmount = validator.totalStake;
            uint256 commission = validator.commission;
            // if validator already present in tree, remove and reinsert to maintain sort
            if (_validators.exists(validatorAddr)) {
                _validators.remove(validatorAddr);
            }
            uint256 updatedStake = uint256(int256(stakeAmount) + item.stake);
            uint256 updatedTotalStake = uint256(
                int256(totalStakeAmount) + item.stake + item.delegation
            );
            _validators.insert(
                validatorAddr,
                updatedStake,
                updatedTotalStake,
                commission
            );
        }
    }

    function stake() external payable onlyValidator {
        // TODO check whitelist
        uint256 currentStake = _validators.stakeOf(msg.sender);
        if (msg.value + currentStake < minSelfStake)
            revert StakeRequirement({src: "stake", msg: "STAKE_TOO_LOW"});
        _queue.insert(msg.sender, int256(msg.value), 0);
        // childValidatorSet.addSelfStake(id, msg.value);
    }

    function unstake(uint256 amount) external onlyValidator {
        int256 totalStake = int256(_validators.stakeOf(msg.sender)) +
            _queue.pendingStake(msg.sender);
        int256 amountInt = int256(amount);
        // prevent overflow
        assert(amountInt > 0);
        if (amountInt > totalStake)
            revert StakeRequirement({src: "unstake", msg: "EXCEEDS_BALANCE"});
        int256 amountAfterUnstake = totalStake - amountInt;
        if (
            amountAfterUnstake < int256(minSelfStake) && amountAfterUnstake != 0
        ) revert StakeRequirement({src: "unstake", msg: "STAKE_TOO_LOW"});
        _queue.insert(msg.sender, amountInt * -1, 0);

        // IChildValidatorSet.Validator memory validator = childValidatorSet
        //     .validators(id);
        // uint256 amountLeft = validator.selfStake - amount;
        // require(
        //     amountLeft >= minSelfStake || amountLeft == 0,
        //     "INVALID_UNSTAKE_AMOUNT"
        // );
        // childValidatorSet.unstake(id, amount);
        // // solhint-disable-next-line avoid-low-level-calls
        // (bool success, ) = to.call{value: amount}("");
        // require(success, "TRANSFER_FAILED");
    }

    // TODO undelegate
    function delegate(address validator, bool restake) external payable {
        // TODO validator verification
        uint256 id = childValidatorSet.validatorIdByAddress(validator);
        require(msg.value >= minDelegation, "DELEGATION_TOO_LOW");

        // require(
        //     id < childValidatorSet.currentValidatorId(),
        //     "INVALID_VALIDATOR_ID"
        // );

        uint256 amount = msg.value;

        Stake storage delegation = delegations[msg.sender][id];

        // delegation.epochId = childValidatorSet.currentEpochId();

        if (restake) {
            uint256 reward = calculateDelegatorReward(id, msg.sender);
            amount += reward;
        } else {
            claimDelegatorReward(id);
        }

        delegation.amount += amount;

        _queue.insert(msg.sender, 0, int256(amount));
    }

    function claimDelegatorReward(uint256 id) public nonReentrant {
        uint256 reward = calculateDelegatorReward(id, msg.sender);

        Stake storage delegation = delegations[msg.sender][id];

        delegation.epochId = childValidatorSet.currentEpochId();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: reward}("");

        require(success, "TRANSFER_FAILED");
    }

    function claimValidatorReward() public onlyValidator nonReentrant {
        uint256 id = childValidatorSet.validatorIdByAddress(msg.sender);
        uint256 reward = calculateValidatorReward(id);

        Stake storage delegation = delegations[msg.sender][id];

        delegation.epochId = childValidatorSet.currentEpochId();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: reward}("");

        require(success, "TRANSFER_FAILED");
    }

    // get first `amount` of validators sorted by stake from high to low
    function sortedValidators(uint256 amount)
        external
        view
        returns (address[] memory)
    {
        uint256 length = amount <= _validators.count
            ? amount
            : _validators.count;
        address[] memory validatorAddresses = new address[](length);

        address tmpValidator = _validators.last();
        validatorAddresses[0] = tmpValidator;

        for (uint256 i = 1; i < length; i++) {
            tmpValidator = _validators.prev(tmpValidator);
            validatorAddresses[i] = tmpValidator;
        }

        return validatorAddresses;
    }

    function calculateDelegatorReward(uint256 id, address delegator)
        public
        view
        returns (uint256)
    {
        Stake memory delegation = delegations[delegator][id];

        uint256 startIndex = delegation.epochId;

        uint256 endIndex = childValidatorSet.currentEpochId() - 1;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * delegatorRewardShares[i][id];
        }

        return totalReward / REWARD_PRECISION;
    }

    function calculateValidatorReward(uint256 id)
        public
        view
        returns (uint256)
    {
        Stake memory delegation = selfStakes[id];

        uint256 startIndex = delegation.epochId;
        uint256 endIndex = childValidatorSet.currentEpochId() - 1;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * validatorRewardShares[i][id];
        }

        return totalReward / REWARD_PRECISION;
    }

    function _calculateValidatorAndDelegatorShares(
        uint256 validatorId,
        uint256 totalReward
    ) internal view returns (uint256, uint256) {
        IChildValidatorSet.Validator memory validator = childValidatorSet
            .validators(validatorId);
        require(validator._address != address(0), "INVALID_VALIDATOR_ID");

        if (validator.totalStake == 0) {
            return (0, 0);
        }

        uint256 rewardShares = (totalReward * REWARD_PRECISION) /
            validator.totalStake;

        if ((validator.totalStake - validator.selfStake) == 0) {
            return (rewardShares, 0);
        }

        uint256 delegatorShares = (totalReward * REWARD_PRECISION) /
            (validator.totalStake - validator.selfStake);

        uint256 commission = (validator.commission * delegatorShares) / 100;

        return (rewardShares - commission, delegatorShares - commission);
    }
}
