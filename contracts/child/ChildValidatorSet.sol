// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {System} from "./System.sol";

interface IStakeManager {
    struct Uptime {
        uint256 epochId;
        uint256[] uptimes;
        uint256 totalUptime;
    }

    function distributeRewards(Uptime calldata uptime) external;

    function processQueue() external;

    function sortedValidators(uint256 n) external view returns (address[] memory);
}

/**
    @title ChildValidatorSet
    @author Polygon Technology
    @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
    @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 */
contract ChildValidatorSet is System, OwnableUpgradeable {
    using ArraysUpgradeable for uint256[];

    struct Validator {
        address _address;
        uint256[4] blsKey;
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
        address[] validatorSet;
    }

    bytes32 public constant NEW_VALIDATOR_SIG = 0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc;
    uint256 public constant SPRINT = 64;
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100; // might want to change later!
    uint256 public constant MAX_VALIDATOR_SET_SIZE = 500;
    uint256 public currentEpochId;

    IStakeManager public stakeManager;

    uint256[] public epochEndBlocks;

    mapping(uint256 => Epoch) public epochs;
    mapping(address => mapping(uint256 => bool)) public validatorsByEpoch;
    mapping(address => bool) public whitelist;

    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);

    modifier onlyStakeManager() {
        require(msg.sender == address(stakeManager), "ONLY_STAKE_MANAGER");
        _;
    }

    /**
     * @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
     * @param governance Governance address to set as owner of the contract
     * @param epochValidatorSet First active validator set
     */
    function initialize(
        IStakeManager newStakeManager,
        address governance,
        address[] calldata epochValidatorSet
    ) external initializer onlySystemCall {
        // slither-disable-next-line missing-zero-check
        stakeManager = newStakeManager;

        Epoch storage nextEpoch = epochs[++currentEpochId];
        nextEpoch.validatorSet = epochValidatorSet;

        _transferOwnership(governance);
    }

    /**
     * @notice Allows the v3 client to commit epochs to this contract.
     * @param id ID of epoch to be committed
     * @param epoch New epoch data to be committed
     * @param uptime Uptime data for the epoch being committed
     */
    function commitEpoch(
        uint256 id,
        Epoch calldata epoch,
        IStakeManager.Uptime calldata uptime
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

        stakeManager.distributeRewards(uptime);
        stakeManager.processQueue();

        _setNextValidatorSet(newEpochId + 1, epoch.epochRoot);

        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    function getCurrentValidatorSet() external view returns (address[] memory) {
        return epochs[currentEpochId].validatorSet;
    }

    /**
     * @notice Look up an epoch by block number. Searches in O(log n) time.
     * @param blockNumber ID of epoch to be committed
     * @return Epoch Returns epoch if found, or else, the last epoch
     */
    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory) {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        return epochs[ret + 1];
    }

    /**
     * @notice Sets the validator set for an epoch using the previous root as seed
     */
    function _setNextValidatorSet(uint256 epochId, bytes32 epochRoot) internal {
        address[] memory activeValidators = stakeManager.sortedValidators(ACTIVE_VALIDATOR_SET_SIZE);

        for (uint256 i = 0; i < activeValidators.length; i++) {
            epochs[epochId].validatorSet.push(activeValidators[i]);
        }
        // // if current total set is less than wanted active validator set size, we include the entire set
        // if (currentId <= validatorSetSize) {
        //     uint256[] memory validatorSet = new uint256[](currentId); // include all validators in set
        //     for (uint256 i = 0; i < currentId; i++) {
        //         validatorSet[i] = i + 1; // validators are one-indexed
        //     }
        //     epochs[epochId].validatorSet = validatorSet;
        //     // else, randomly pick active validator set from total validator set
        // } else {
        //     uint256[] memory validatorSet = new uint256[](validatorSetSize);
        //     uint256 counter = 0;
        //     for (uint256 i = 0; ; i++) {
        //         // use epoch root with seed and pick a random index
        //         uint256 randomIndex = uint256(keccak256(abi.encodePacked(epochRoot, i))) % currentId;
        //         // if validator picked, skip iteration
        //         if (validatorsByEpoch[epochId][randomIndex]) {
        //             continue;
        //             // else, add validator and include in set
        //         } else {
        //             validatorsByEpoch[epochId][randomIndex] = true;
        //             validatorSet[counter++] = randomIndex;
        //         }
        //         if (validatorSet[validatorSetSize - 1] != 0) {
        //             break; // last element filled, break
        //         }
        //     }
        //     epochs[epochId].validatorSet = validatorSet;
        // }
    }
}
