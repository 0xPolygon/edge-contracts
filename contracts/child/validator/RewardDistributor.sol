// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../System.sol";
import "../../interfaces/child/validator/IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, System, ReentrancyGuardUpgradeable {
    RewardToken public REWARD_TOKEN;
    IValidatorSet public VALIDATOR_SET;
    uint256 public BASE_REWARD;

    mapping(uint256 => uint256) public paidRewardPerEpoch;
    mapping(address => uint256) public pendingRewards;

    function initialize(
        address rewardToken,
        address validatorSet,
        uint256 baseReward
    ) external initializer onlySystemCall {
        REWARD_TOKEN = RewardToken(rewardToken);
        VALIDATOR_SET = IValidatorSet(validatorSet);
        BASE_REWARD = baseReward;
    }

    /**
     * @inheritdoc IRewardDistributor
     */
    function distributeRewardFor(uint256 epochId, Uptime calldata uptime) external onlySystemCall {
        require(paidRewardPerEpoch[epochId] == 0, "REWARD_ALREADY_DISTRIBUTED");
        uint256 totalBlocks = VALIDATOR_SET.totalBlocks(epochId);
        require(totalBlocks != 0, "EPOCH_NOT_COMMITTED");
        uint256 epochSize = VALIDATOR_SET.EPOCH_SIZE();
        uint256 reward = (BASE_REWARD * totalBlocks * 100) / (epochSize * 100);

        uint256 totalSupply = VALIDATOR_SET.totalSupplyAt(epochId);
        uint256 length = uptime.uptimeData.length;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < length; i++) {
            UptimeData memory data = uptime.uptimeData[i];
            assert(data.signedBlocks <= totalBlocks);
            uint256 balance = VALIDATOR_SET.balanceOfAt(data.validator, epochId);
            uint256 validatorReward = (reward * balance * data.signedBlocks) / (totalSupply * totalBlocks);
            pendingRewards[data.validator] += validatorReward;
            totalReward += validatorReward;
        }
        paidRewardPerEpoch[epochId] = totalReward;
        _transferRewards(totalReward);
    }

    /**
     * @inheritdoc IRewardDistributor
     */
    function withdrawReward() external {
        uint256 pendingReward = pendingRewards[msg.sender];
        pendingRewards[msg.sender] = 0;
        REWARD_TOKEN.transfer(msg.sender, pendingReward);
    }

    /// @dev this method can be overridden to add logic depending on the reward token
    function _transferRewards(uint256 amount) internal virtual {
        REWARD_TOKEN.mintRewards(amount);
    }
}
