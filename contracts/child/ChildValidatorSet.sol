// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../common/Owned.sol";
import "./System.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "../libs/ValidatorStorage.sol";
import "../libs/ValidatorQueue.sol";
import "../libs/WithdrawalQueue.sol";
import "../interfaces/IBLS.sol";
import "../interfaces/IChildValidatorSet.sol";

import "hardhat/console.sol";

contract ChildValidatorSet is System, Owned, ReentrancyGuardUpgradeable, IChildValidatorSet {
    using ArraysUpgradeable for uint256[];
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;
    using WithdrawalQueueLib for WithdrawalQueue;

    bytes32 public constant NEW_VALIDATOR_SIG = 0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc;
    uint256 public constant SPRINT = 64;
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100; // might want to change later!
    uint256 public constant MAX_VALIDATOR_SET_SIZE = 500;
    uint256 public constant REWARD_PRECISION = 10**18;
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;
    uint256 public constant MAX_COMMISSION = 100;

    uint256 public currentEpochId;
    uint256[] public epochEndBlocks;
    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;

    IBLS public bls;
    uint256[2] public message;

    ValidatorTree private _validators;
    ValidatorQueue private _queue;
    mapping(address => WithdrawalQueue) private _withdrawals;
    mapping(uint256 => Epoch) public epochs;
    mapping(address => mapping(uint256 => bool)) public validatorsByEpoch;

    mapping(address => mapping(uint256 => uint256)) public totalRewards; // validator address -> epoch -> amount
    mapping(uint256 => mapping(address => uint256)) public validatorRewardShares; // epoch -> validator address -> amount
    mapping(uint256 => mapping(address => uint256)) public delegatorRewardShares; // epoch -> validator address -> reward per share
    mapping(address => mapping(address => Stake)) public delegations; // user address -> validator address -> Delegation
    mapping(address => Stake) public selfStakes; // validator address -> Delegation
    mapping(address => bool) public whitelist;

    modifier onlyValidator() {
        if (!whitelist[msg.sender]) revert Unauthorized("VALIDATOR");
        _;
    }

    /// @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
    /// @param governance Governance address to set as owner of the contract
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

        epochReward = newEpochReward;
        minStake = newMinStake;
        minDelegation = newMinDelegation;

        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            _addToWhitelist(validatorAddresses[i]);
            Validator memory validator = Validator({
                blsKey: validatorPubkeys[i],
                stake: validatorStakes[i],
                totalStake: validatorStakes[i],
                commission: 0
            });
            _validators.insert(validatorAddresses[i], validator);
        }
        bls = newBls;
        message = newMessage;
    }

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

    function getCurrentValidatorSet() external view returns (address[] memory) {
        return sortedValidators(ACTIVE_VALIDATOR_SET_SIZE);
    }

    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory) {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        return epochs[ret + 1];
    }

    function addToWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _addToWhitelist(whitelistAddreses[i]);
        }
    }

    function removeFromWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _removeFromWhitelist(whitelistAddreses[i]);
        }
    }

    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external onlyValidator {
        (bool result, bool callSuccess) = bls.verifySingle(signature, pubkey, message);
        require(callSuccess && result, "INVALID_SIGNATURE");

        _validators.insert(msg.sender, Validator({blsKey: pubkey, stake: 0, totalStake: 0, commission: 0}));
        // whitelist[msg.sender] = false;

        emit NewValidator(msg.sender, pubkey);
    }

    function stake() external payable onlyValidator {
        // TODO check for BLS key or introduce additional variable to check if validator is registered
        uint256 currentStake = _validators.stakeOf(msg.sender);
        if (msg.value + currentStake < minStake) revert StakeRequirement({src: "stake", msg: "STAKE_TOO_LOW"});
        _queue.insert(msg.sender, int256(msg.value), 0);
    }

    function unstake(uint256 amount) external {
        int256 totalValidatorStake = int256(_validators.stakeOf(msg.sender)) + _queue.pendingStake(msg.sender);
        int256 amountInt = int256(amount);
        // prevent overflow
        assert(amountInt > 0);
        if (amountInt > totalValidatorStake) revert StakeRequirement({src: "unstake", msg: "INSUFFICIENT_BALANCE"});
        int256 amountAfterUnstake = totalValidatorStake - amountInt;
        if (amountAfterUnstake < int256(minStake) && amountAfterUnstake != 0)
            revert StakeRequirement({src: "unstake", msg: "STAKE_TOO_LOW"});
        _queue.insert(msg.sender, amountInt * -1, 0);
        if (amountAfterUnstake == 0) {
            _removeFromWhitelist(msg.sender);
        }
        _registerWithdrawal(msg.sender, amount);
    }

    function delegate(address validator, bool restake) external payable {
        if (!whitelist[validator]) revert Unauthorized("INVALID_VALIDATOR");

        Stake storage delegation = delegations[msg.sender][validator];
        require(delegation.amount + msg.value >= minDelegation, "DELEGATION_TOO_LOW");

        claimDelegatorReward(validator, restake);

        _queue.insert(msg.sender, 0, int256(msg.value));
        delegation.amount += msg.value;
    }

    function claimValidatorReward() public onlyValidator {
        // uint256 id = childValidatorSet.validatorIdByAddress(msg.sender);
        uint256 reward = calculateValidatorReward(msg.sender);
        Stake storage delegation = delegations[msg.sender][msg.sender];
        delegation.epochId = currentEpochId;
        _registerWithdrawal(msg.sender, reward);
    }

    function claimDelegatorReward(address validator, bool restake) public {
        uint256 reward = calculateDelegatorReward(validator, msg.sender);

        Stake storage delegation = delegations[msg.sender][validator];
        delegation.epochId = currentEpochId;
        // update epochId before returning
        if (reward == 0) return;

        if (restake) {
            _queue.insert(msg.sender, 0, int256(reward));
            delegation.amount += reward;
        } else {
            _registerWithdrawal(msg.sender, reward);
        }
    }

    function setCommission(uint256 newCommission) external onlyValidator {
        require(newCommission <= MAX_COMMISSION, "INVALID_COMMISSION");
        Validator storage validator = _validators.get(msg.sender);
        validator.commission = newCommission;
    }

    function getValidator(address validator) public view returns (Validator memory) {
        return _validators.get(validator);
    }

    function sortedValidators(uint256 n) public view returns (address[] memory) {
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

    function totalStake() public view returns (uint256) {
        return _validators.totalStake;
    }

    function withdrawable(address account) public view returns (uint256) {
        return _withdrawals[account].withdrawable(currentEpochId);
    }

    function pendingWithdrawals(address account) public view returns (uint256) {
        return _withdrawals[account].pending(currentEpochId);
    }

    function calculateDelegatorReward(address validator, address delegator) public view returns (uint256) {
        Stake memory delegation = delegations[delegator][validator];

        uint256 startIndex = delegation.epochId;

        uint256 endIndex = currentEpochId - 1;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * delegatorRewardShares[i][validator];
        }

        return totalReward / REWARD_PRECISION;
    }

    function calculateValidatorReward(address validator) public view returns (uint256) {
        Stake memory delegation = selfStakes[validator];

        uint256 startIndex = delegation.epochId;
        uint256 endIndex = currentEpochId - 1;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * validatorRewardShares[i][validator];
        }

        return totalReward / REWARD_PRECISION;
    }

    function _distributeRewards(Uptime calldata uptime) private {
        require(uptime.epochId == currentEpochId - 1, "EPOCH_NOT_COMMITTED");

        uint256 length = uptime.uptimeData.length;

        require(length <= ACTIVE_VALIDATOR_SET_SIZE && length <= _validators.count, "INVALID_LENGTH");

        uint256[] memory weights = new uint256[](length);
        uint256 aggPower = 0;
        uint256 aggWeight = 0;

        for (uint256 i = 0; i < length; ++i) {
            uint256 power = _calculateValidatorPower(uptime.uptimeData[i].validator);
            aggPower += power;
            weights[i] = uptime.uptimeData[i].uptime * power;
            aggWeight += weights[i];
        }

        require(aggPower > (66 * (10**6)), "NOT_ENOUGH_CONSENSUS");

        uint256 reward = epochReward;

        reward = (reward * aggPower) / (100 * (10**6)); // scale reward to power staked

        for (uint256 i = 0; i < length; ++i) {
            address validator = uptime.uptimeData[i].validator;
            uint256 validatorReward = (reward * weights[i]) / aggWeight;
            (uint256 validatorShares, uint256 delegatorShares) = _calculateValidatorAndDelegatorShares(
                validator,
                validatorReward
            );
            validatorRewardShares[uptime.epochId][validator] = validatorShares;
            delegatorRewardShares[uptime.epochId][validator] = delegatorShares;
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
            validator.stake = uint256(int256(validator.stake) + item.stake);
            validator.totalStake = uint256(int256(validator.totalStake) + item.stake + item.delegation);
            _validators.insert(validatorAddr, validator);
            _queue.resetIndex(validatorAddr);
        }
        _queue.reset();
    }

    function _registerWithdrawal(address account, uint256 amount) private {
        _withdrawals[account].append(amount, currentEpochId + WITHDRAWAL_WAIT_PERIOD);
    }

    function _addToWhitelist(address account) private {
        whitelist[account] = true;
    }

    function _removeFromWhitelist(address account) private {
        whitelist[account] = false;
    }

    /// @notice Calculate validator power for a validator in percentage.
    /// @return uint256 Returns validator power at 6 decimals. Therefore, a return value of 123456 is 0.123456%
    function _calculateValidatorPower(address validator) private view returns (uint256) {
        /* 6 decimals is somewhat arbitrary selected, but if we work backwards:
           MATIC total supply = 10 billion, smallest validator = 1997 MATIC, power comes to 0.00001997% */
        return (_validators.get(validator).stake * 100 * (10**6)) / _validators.totalStake;
    }

    function _calculateValidatorAndDelegatorShares(address validatorAddr, uint256 totalReward)
        private
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
}
