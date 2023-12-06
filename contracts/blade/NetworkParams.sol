// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct InitParams {
    address newOwner;
    uint256 newCheckpointBlockInterval; // in blocks
    uint256 newEpochSize; // in blocks
    uint256 newEpochReward; // in wei
    uint256 newSprintSize; // in blocks
    uint256 newMinValidatorSetSize;
    uint256 newMaxValidatorSetSize;
    uint256 newWithdrawalWaitPeriod; // in blocks
    uint256 newBlockTime; // in seconds
    uint256 newBlockTimeDrift; // in seconds
    uint256 newVotingDelay; // in blocks
    uint256 newVotingPeriod; // in blocks
    uint256 newProposalThreshold; // in percent
    uint256 newBaseFeeChangeDenom; // in wei
}

/**
    @title NetworkParams
    @author Polygon Technology (@QEDK)
    @notice Configurable network parameters that are read by the client on each epoch
    @dev The contract allows for configurable network parameters without the need for a hardfork
 */
contract NetworkParams is Ownable2Step, Initializable {
    uint256 public checkpointBlockInterval; // in blocks
    uint256 public epochSize; // in blocks
    uint256 public epochReward; // in wei
    uint256 public sprintSize; // in blocks
    uint256 public minValidatorSetSize;
    uint256 public maxValidatorSetSize;
    uint256 public withdrawalWaitPeriod; // in blocks
    uint256 public blockTime; // in seconds
    uint256 public blockTimeDrift; // in seconds
    uint256 public votingDelay; // in blocks
    uint256 public votingPeriod; // in blocks
    uint256 public proposalThreshold; // in percent
    uint256 public baseFeeChangeDenom; // in wei

    event NewCheckpointBlockInterval(uint256 indexed checkpointInterval);
    event NewEpochSize(uint256 indexed size);
    event NewEpochReward(uint256 indexed reward);
    event NewSprintSize(uint256 indexed size);
    event NewMinValidatorSetSize(uint256 indexed minValidatorSet);
    event NewMaxValidatorSetSize(uint256 indexed maxValidatorSet);
    event NewWithdrawalWaitPeriod(uint256 indexed withdrawalPeriod);
    event NewBlockTime(uint256 indexed blockTime);
    event NewBlockTimeDrift(uint256 indexed blockTimeDrift);
    event NewVotingDelay(uint256 indexed votingDelay);
    event NewVotingPeriod(uint256 indexed votingPeriod);
    event NewProposalThreshold(uint256 indexed proposalThreshold);
    event NewBaseFeeChangeDenom(uint256 indexed baseFeeChangeDenom);

    /**
     * @notice initializer for NetworkParams, sets the initial set of values for the network
     * @dev disallows setting of zero values for sanity check purposes
     * @param initParams initial set of values for the network
     */
    function initialize(InitParams memory initParams) public initializer {
        require(
            initParams.newOwner != address(0) &&
                initParams.newCheckpointBlockInterval != 0 &&
                initParams.newEpochSize != 0 &&
                initParams.newSprintSize != 0 &&
                initParams.newMinValidatorSetSize != 0 &&
                initParams.newMaxValidatorSetSize != 0 &&
                initParams.newWithdrawalWaitPeriod != 0 &&
                initParams.newBlockTime != 0 &&
                initParams.newBlockTimeDrift != 0 &&
                initParams.newVotingPeriod != 0,
            "NetworkParams: INVALID_INPUT"
        );
        checkpointBlockInterval = initParams.newCheckpointBlockInterval;
        epochSize = initParams.newEpochSize;
        epochReward = initParams.newEpochReward;
        sprintSize = initParams.newSprintSize;
        minValidatorSetSize = initParams.newMinValidatorSetSize;
        maxValidatorSetSize = initParams.newMaxValidatorSetSize;
        withdrawalWaitPeriod = initParams.newWithdrawalWaitPeriod;
        blockTime = initParams.newBlockTime;
        blockTimeDrift = initParams.newBlockTimeDrift;
        votingDelay = initParams.newVotingDelay;
        votingPeriod = initParams.newVotingPeriod;
        proposalThreshold = initParams.newProposalThreshold;
        baseFeeChangeDenom = initParams.newBaseFeeChangeDenom;
        _transferOwnership(initParams.newOwner);
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
     * @notice function to set new epoch size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newEpochSize new epoch reward
     */
    function setNewEpochSize(uint256 newEpochSize) external onlyOwner {
        require(newEpochSize != 0, "NetworkParams: INVALID_EPOCH_SIZE");
        epochSize = newEpochSize;

        emit NewEpochSize(newEpochSize);
    }

    /**
     * @notice function to set new epoch reward
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newEpochReward new epoch reward
     */
    function setNewEpochReward(uint256 newEpochReward) external onlyOwner {
        epochReward = newEpochReward;

        emit NewEpochReward(newEpochReward);
    }

    /**
     * @notice function to set new sprint size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newSprintSize new sprint size
     */
    function setNewSprintSize(uint256 newSprintSize) external onlyOwner {
        require(newSprintSize != 0, "NetworkParams: INVALID_SPRINT_SIZE");
        sprintSize = newSprintSize;

        emit NewSprintSize(newSprintSize);
    }

    /**
     * @notice function to set new minimum validator set size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMinValidatorSetSize new minimum validator set size
     */
    // slither-disable-next-line similar-names
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
    // slither-disable-next-line similar-names
    function setNewMaxValidatorSetSize(uint256 newMaxValidatorSetSize) external onlyOwner {
        require(newMaxValidatorSetSize != 0, "NetworkParams: INVALID_MAX_VALIDATOR_SET_SIZE");
        maxValidatorSetSize = newMaxValidatorSetSize;

        emit NewMaxValidatorSetSize(newMaxValidatorSetSize);
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
        proposalThreshold = newProposalThreshold;

        emit NewProposalThreshold(newProposalThreshold);
    }

    /**
     * @notice function to set new base fee change denominator
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newBaseFeeChangeDenom new base fee change denominator
     */
    function setNewBaseFeeChangeDenom(uint256 newBaseFeeChangeDenom) external onlyOwner {
        require(newBaseFeeChangeDenom != 0, "NetworkParams: INVALID_BASE_FEE_CHANGE_DENOM");
        baseFeeChangeDenom = newBaseFeeChangeDenom;

        emit NewBaseFeeChangeDenom(newBaseFeeChangeDenom);
    }
}
