// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title NetworkParams
    @author Polygon Technology (@QEDK)
    @notice Configurable network parameters that are read by the client on each epoch
    @dev The contract allows for configurable network parameters without the need for a hardfork
 */
contract NetworkParams is Ownable {
    struct Params {
        address newOwner;
        uint256 newBlockGasLimit;
        uint256 newCheckpointBlockInterval; // in blocks
        uint256 newEpochReward;
        uint256 newMinValidatorSetSize;
        uint256 newMaxValidatorSetSize;
        uint256 newMinStake; // in wei
        uint256 newWithdrawalWaitPeriod;
        uint256 newBlockTime;
        uint256 newBlockTimeDrift;
        uint256 newVotingDelay;
        uint256 newVotingPeriod;
        uint256 newProposalThreshold;
    }

    uint256 public blockGasLimit;
    uint256 public checkpointBlockInterval; // in blocks
    uint256 public epochReward;
    uint256 public minValidatorSetSize;
    uint256 public maxValidatorSetSize;
    uint256 public minStake; // in wei
    uint256 public withdrawalWaitPeriod;
    uint256 public blockTime;
    uint256 public blockTimeDrift;
    uint256 public votingDelay;
    uint256 public votingPeriod;
    uint256 public proposalThreshold;

    event NewBlockGasLimit(uint256 indexed value);
    event NewCheckpointBlockInterval(uint256 indexed value);
    event NewEpochReward(uint256 indexed value);
    event NewMinValidatorSetSize(uint256 indexed value);
    event NewMaxValdidatorSetSize(uint256 indexed value);
    event NewMinStake(uint256 indexed value);
    event NewWithdrawalWaitPeriod(uint256 indexed value);
    event NewBlockTime(uint256 indexed value);
    event NewBlockTimeDrift(uint256 indexed value);
    event NewVotingDelay(uint256 indexed value);
    event NewVotingPeriod(uint256 indexed value);
    event NewProposalThreshold(uint256 indexed value);

    /**
     * @notice initializer for NetworkParams, sets the initial set of values for the network
     * @dev disallows setting of zero values for sanity check purposes
     * @param _params initial set of values for the network
     */
    constructor(Params memory _params) {
        require(
            _params.newOwner != address(0) &&
                _params.newBlockGasLimit != 0 &&
                _params.newCheckpointBlockInterval != 0 &&
                _params.newEpochReward != 0 &&
                _params.newMinValidatorSetSize != 0 &&
                _params.newMaxValidatorSetSize != 0 &&
                _params.newMinStake != 0 &&
                _params.newWithdrawalWaitPeriod != 0 &&
                _params.newBlockTime != 0 &&
                _params.newBlockTimeDrift != 0 &&
                _params.newVotingDelay != 0 &&
                _params.newVotingPeriod != 0 &&
                _params.newProposalThreshold != 0,
            "NetworkParams: INVALID_INPUT"
        );
        blockGasLimit = _params.newBlockGasLimit;
        checkpointBlockInterval = _params.newCheckpointBlockInterval;
        epochReward = _params.newEpochReward;
        minValidatorSetSize = _params.newMinValidatorSetSize;
        maxValidatorSetSize = _params.newMaxValidatorSetSize;
        minStake = _params.newMinStake;
        withdrawalWaitPeriod = _params.newWithdrawalWaitPeriod;
        blockTime = _params.newBlockTime;
        blockTimeDrift = _params.newBlockTimeDrift;
        votingDelay = _params.newVotingDelay;
        votingPeriod = _params.newVotingPeriod;
        proposalThreshold = _params.newProposalThreshold;
        _transferOwnership(_params.newOwner);
    }

    /**
     * @notice function to set new block gas limit
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newBlockGasLimit new block gas limit
     */
    function setNewBlockGasLimit(uint256 newBlockGasLimit) external onlyOwner {
        require(newBlockGasLimit != 0, "NetworkParams: INVALID_BLOCK_GAS_LIMIT");
        blockGasLimit = newBlockGasLimit;

        emit NewBlockGasLimit(newBlockGasLimit);
    }

    /**
     * @notice function to set new checkpoint block interval
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newCheckpointBlockInterval new checkpoint block interval
     */
    function setNewCheckpointBlockInterval(uint256 newCheckpointBlockInterval) external onlyOwner {
        require(newCheckpointBlockInterval != 0, "NetworkParams: INVALID_CHECKPOINT_INTERVAL");
        checkpointBlockInterval = newCheckpointBlockInterval;

        emit NewCheckpointBlockInterval(newCheckpointBlockInterval);
    }

    /**
     * @notice function to set new epoch reward
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newEpochReward new epoch reward
     */
    function setNewEpochReward(uint256 newEpochReward) external onlyOwner {
        require(newEpochReward != 0, "NetworkParams: INVALID_EPOCH_REWARD");
        epochReward = newEpochReward;

        emit NewEpochReward(newEpochReward);
    }

    /**
     * @notice function to set new minimum validator set size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMinValidatorSetSize new minimum validator set size
     */
    function setNewMinValidatorSetSize(uint256 newMinValidatorSetSize) external onlyOwner {
        require(newMinValidatorSetSize != 0, "NetworkParams: INVALID_MIN_VALIDATOR_SET_SIZE");
        minValidatorSetSize = newMinValidatorSetSize;

        emit NewMinValidatorSetSize(newMinValidatorSetSize);
    }

    /**
     * @notice function to set new maximum validator set size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMaxValidatorSetSize new maximum validator set size
     */
    function setNewMaxValidatorSetSize(uint256 newMaxValidatorSetSize) external onlyOwner {
        require(newMaxValidatorSetSize != 0, "NetworkParams: INVALID_MAX_VALIDATOR_SET_SIZE");
        maxValidatorSetSize = newMaxValidatorSetSize;

        emit NewMaxValdidatorSetSize(newMaxValidatorSetSize);
    }

    /**
     * @notice function to set new minimum stake
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMinStake new minimum stake
     */
    function setNewMinStake(uint256 newMinStake) external onlyOwner {
        require(newMinStake != 0, "NetworkParams: INVALID_MIN_STAKE");
        minStake = newMinStake;

        emit NewMinStake(newMinStake);
    }

    /**
     * @notice function to set new withdrawal wait period
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newWithdrawalWaitPeriod new withdrawal wait period
     */
    function setNewWithdrawalWaitPeriod(uint256 newWithdrawalWaitPeriod) external onlyOwner {
        require(newWithdrawalWaitPeriod != 0, "NetworkParams: INVALID_WITHDRAWAL_WAIT_PERIOD");
        withdrawalWaitPeriod = newWithdrawalWaitPeriod;

        emit NewWithdrawalWaitPeriod(newWithdrawalWaitPeriod);
    }

    /**
     * @notice function to set new block time
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newBlockTime new block time
     */
    function setNewBlockTime(uint256 newBlockTime) external onlyOwner {
        require(newBlockTime != 0, "NetworkParams: INVALID_BLOCK_TIME");
        blockTime = newBlockTime;

        emit NewBlockTime(newBlockTime);
    }

    /**
     * @notice function to set new block time drift
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newBlockTimeDrift new block time drift
     */
    function setNewBlockTimeDrift(uint256 newBlockTimeDrift) external onlyOwner {
        require(newBlockTimeDrift != 0, "NetworkParams: INVALID_BLOCK_TIME_DRIFT");
        blockTimeDrift = newBlockTimeDrift;

        emit NewBlockTimeDrift(newBlockTimeDrift);
    }

    /**
     * @notice function to set new voting delay
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newVotingDelay new voting delay
     */
    function setNewVotingDelay(uint256 newVotingDelay) external onlyOwner {
        require(newVotingDelay != 0, "NetworkParams: INVALID_VOTING_DELAY");
        votingDelay = newVotingDelay;

        emit NewVotingDelay(newVotingDelay);
    }

    /**
     * @notice function to set new voting period
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newVotingPeriod new voting period
     */
    function setNewVotingPeriod(uint256 newVotingPeriod) external onlyOwner {
        require(newVotingPeriod != 0, "NetworkParams: INVALID_VOTING_PERIOD");
        votingPeriod = newVotingPeriod;

        emit NewVotingPeriod(newVotingPeriod);
    }

    /**
     * @notice function to set new proposal threshold
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newProposalThreshold new proposal threshold
     */
    function setNewProposalThreshold(uint256 newProposalThreshold) external onlyOwner {
        require(newProposalThreshold != 0, "NetworkParams: INVALID_PROPOSAL_THRESHOLD");
        proposalThreshold = newProposalThreshold;

        emit NewProposalThreshold(newProposalThreshold);
    }
}
