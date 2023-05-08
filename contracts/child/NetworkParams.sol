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
    uint256 public blockGasLimit;
    uint256 public checkpointBlockInterval; // in blocks
    uint256 public minStake; // in wei
    uint256 public maxValidatorSetSize;

    event NewBlockGasLimit(uint256 indexed value);
    event NewCheckpointBlockInterval(uint256 indexed value);
    event NewMinStake(uint256 indexed value);
    event NewMaxValdidatorSetSize(uint256 indexed value);

    /**
     * @notice initializer for NetworkParams, sets the initial set of values for the network
     * @dev disallows setting of zero values for sanity check purposes
     * @param newOwner address of the contract controller to be set at deployment
     * @param newBlockGasLimit initial block gas limit
     * @param newCheckpointBlockInterval initial checkpoint interval
     * @param newMinStake initial minimum stake
     * @param newMaxValidatorSetSize initial max validator set size
     */
    constructor(
        address newOwner,
        uint256 newBlockGasLimit,
        uint256 newCheckpointBlockInterval,
        uint256 newMinStake,
        uint256 newMaxValidatorSetSize
    ) {
        require(
            newOwner != address(0) &&
                newBlockGasLimit != 0 &&
                newMinStake != 0 &&
                newCheckpointBlockInterval != 0 &&
                newMaxValidatorSetSize != 0,
            "NetworkParams: INVALID_INPUT"
        );
        blockGasLimit = newBlockGasLimit;
        checkpointBlockInterval = newCheckpointBlockInterval;
        minStake = newMinStake;
        maxValidatorSetSize = newMaxValidatorSetSize;
        _transferOwnership(newOwner);
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
     * @notice function to set new maximum validator set size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMaxValidatorSetSize new maximum validator set size
     */
    function setNewMaxValidatorSetSize(uint256 newMaxValidatorSetSize) external onlyOwner {
        require(newMaxValidatorSetSize != 0, "NetworkParams: INVALID_MAX_VALIDATOR_SET_SIZE");
        maxValidatorSetSize = newMaxValidatorSetSize;

        emit NewMaxValdidatorSetSize(newMaxValidatorSetSize);
    }
}
