// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/modules/ICVSStaking.sol";
import "./CVSStorage.sol";
import "./CVSAccessControl.sol";
import "./CVSWithdrawal.sol";
import "../../interfaces/Errors.sol";

import "../../libs/ValidatorStorage.sol";
import "../../libs/ValidatorQueue.sol";
import "../../libs/SafeMathInt.sol";

abstract contract CVSStaking is ICVSStaking, CVSStorage, CVSAccessControl, CVSWithdrawal {
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;
    using SafeMathUint for uint256;

    modifier onlyValidator() {
        if (!_validators.get(msg.sender).active) revert Unauthorized("VALIDATOR");
        _;
    }

    /**
     * @inheritdoc ICVSStaking
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external {
        if (!whitelist[msg.sender]) revert Unauthorized("WHITELIST");

        verifyValidatorRegistration(msg.sender, signature, pubkey);

        _validators.insert(
            msg.sender,
            Validator({blsKey: pubkey, stake: 0, commission: 0, withdrawableRewards: 0, active: true})
        );
        _removeFromWhitelist(msg.sender);

        emit NewValidator(msg.sender, pubkey);
    }

    /**
     * @inheritdoc ICVSStaking
     */
    function stake() external payable onlyValidator {
        int256 totalValidatorStake = int256(_validators.stakeOf(msg.sender)) + _queue.pendingStake(msg.sender);
        if (msg.value.toInt256Safe() + totalValidatorStake < int256(minStake))
            revert StakeRequirement({src: "stake", msg: "STAKE_TOO_LOW"});
        claimValidatorReward();
        _queue.insert(msg.sender, int256(msg.value), 0);
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @inheritdoc ICVSStaking
     */
    function unstake(uint256 amount) external {
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
     * @inheritdoc ICVSStaking
     */
    function setCommission(uint256 newCommission) external onlyValidator {
        require(newCommission <= MAX_COMMISSION, "INVALID_COMMISSION");
        Validator storage validator = _validators.get(msg.sender);
        emit CommissionUpdated(msg.sender, validator.commission, newCommission);
        validator.commission = newCommission;
    }

    /**
     * @inheritdoc ICVSStaking
     */
    function claimValidatorReward() public {
        Validator storage validator = _validators.get(msg.sender);
        uint256 reward = validator.withdrawableRewards;
        if (reward == 0) return;
        validator.withdrawableRewards = 0;
        _registerWithdrawal(msg.sender, reward);
        emit ValidatorRewardClaimed(msg.sender, reward);
    }

    /**
     * @inheritdoc ICVSStaking
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
     * @inheritdoc ICVSStaking
     */
    function getValidatorReward(address validator) external view returns (uint256) {
        return _validators.get(validator).withdrawableRewards;
    }

    /**
     * @inheritdoc ICVSStaking
     */
    function totalStake() external view returns (uint256) {
        return _validators.totalStake;
    }

    /**
     * @inheritdoc ICVSStaking
     */
    function totalStakeOf(address validator) external view returns (uint256) {
        return _validators.totalStakeOf(validator);
    }

    function _distributeValidatorReward(address validator, uint256 reward) internal {
        Validator storage _validator = _validators.get(validator);
        _validator.withdrawableRewards += reward;
        emit ValidatorRewardDistributed(validator, reward);
    }
}
