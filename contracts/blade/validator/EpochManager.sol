// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../System.sol";
import "../../interfaces/blade/validator/IEpochManager.sol";
import "../../blade/NetworkParams.sol";

contract EpochManager is IEpochManager, System, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ERC20SnapshotUpgradeable public stakeManager;
    IERC20Upgradeable public rewardToken;
    NetworkParams public networkParams;
    address public rewardWallet;

    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;

    mapping(uint256 => uint256) public paidRewardPerEpoch;
    mapping(address => uint256) public pendingRewards;
    mapping(uint256 => uint256) public epochEndingBlocks;

    function initialize(
        address newStakeManager,
        address newRewardToken,
        address newRewardWallet,
        address newNetworkParams
    ) public initializer {
        require(newStakeManager != address(0), "EpochManager: INVALID_STAKE_MANAGER");
        require(newRewardToken != address(0), "EpochManager: INVALID_REWARD_TOKEN");
        require(newRewardWallet != address(0), "EpochManager: INVALID_REWARD_WALLET");
        require(newNetworkParams != address(0), "EpochManager: INVALID_NETWORK_PARAMS");

        stakeManager = ERC20SnapshotUpgradeable(newStakeManager);
        networkParams = NetworkParams(newNetworkParams);
        rewardToken = IERC20Upgradeable(newRewardToken);
        rewardWallet = newRewardWallet;

        currentEpochId = 1;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function distributeRewardFor(uint256 epochId, uint256 epochSize, Uptime[] calldata uptime) external onlySystemCall {
        require(paidRewardPerEpoch[epochId] == 0, "REWARD_ALREADY_DISTRIBUTED");
        uint256 totalBlocks = _totalBlocks(epochId);
        require(totalBlocks != 0, "EPOCH_NOT_COMMITTED");
        // slither-disable-next-line divide-before-multiply
        uint256 reward = (networkParams.epochReward() * totalBlocks) / epochSize;
        // TODO disincentivize long epoch times

        uint256 totalSupply = stakeManager.totalSupplyAt(epochId);
        uint256 length = uptime.length;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < length; i++) {
            Uptime memory data = uptime[i];
            require(data.signedBlocks <= totalBlocks, "SIGNED_BLOCKS_EXCEEDS_TOTAL");
            // slither-disable-next-line calls-loop
            uint256 balance = stakeManager.balanceOfAt(data.validator, epochId);
            // slither-disable-next-line divide-before-multiply
            uint256 validatorReward = (reward * balance * data.signedBlocks) / (totalSupply * totalBlocks);
            pendingRewards[data.validator] += validatorReward;
            totalReward += validatorReward;
        }
        paidRewardPerEpoch[epochId] = totalReward;
        _transferRewards(totalReward);
        emit RewardDistributed(epochId, totalReward);
    }

    /**
     * @inheritdoc IEpochManager
     */
    function commitEpoch(uint256 id, uint256 epochSize, Epoch calldata epoch) external onlySystemCall {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(epoch.endBlock > epoch.startBlock, "NO_BLOCKS_COMMITTED");
        require((epoch.endBlock - epoch.startBlock + 1) % epochSize == 0, "EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
        require(epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock, "INVALID_START_BLOCK");
        epochEndingBlocks[newEpochId] = block.number;
        epochs[newEpochId] = epoch;
        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    /**
     * @inheritdoc IEpochManager
     */
    function withdrawReward() external {
        uint256 pendingReward = pendingRewards[msg.sender];
        pendingRewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, pendingReward);
    }

    /// @dev this method can be overridden to add logic depending on the reward token
    function _transferRewards(uint256 amount) internal virtual {
        // slither-disable-next-line arbitrary-send-erc20
        rewardToken.safeTransferFrom(rewardWallet, address(this), amount);
    }

    function _totalBlocks(uint256 epochId) internal view returns (uint256 length) {
        uint256 endBlock = epochs[epochId].endBlock;
        length = endBlock == 0 ? 0 : endBlock - epochs[epochId].startBlock + 1;
    }
}
