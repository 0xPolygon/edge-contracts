// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/ChildValidatorSet/ICVSStakingRewards.sol";
import "./CVSWithdrawal.sol";
import "./CVSStorage.sol";

contract CVSStakingRewards is ICVSStakingRewards, CVSStorage, CVSWithdrawal {
    using ValidatorStorageLib for ValidatorTree;

    /**
     * @inheritdoc ICVSStakingRewards
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
     * @inheritdoc ICVSStakingRewards
     */
    function getValidatorReward(address validator) external view returns (uint256) {
        return getValidator(validator).withdrawableRewards;
    }

    function _distributeValidatorReward(address validator, uint256 reward) internal {
        Validator storage _validator = _validators.get(validator);
        _validator.withdrawableRewards += reward;
        emit ValidatorRewardDistributed(validator, reward);
    }
}
