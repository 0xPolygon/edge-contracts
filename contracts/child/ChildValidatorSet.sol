// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {System} from "./System.sol";

interface IBLS {
    function verifySingle(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    ) external view returns (bool, bool);
}

interface IStakeManager {
    struct Uptime {
        uint256 epochId;
        uint256[] uptimes;
        uint256 totalUptime;
    }

    function distributeRewards(Uptime calldata uptime) external;
}

/**
    @title ChildValidatorSet
    @author Polygon Technology
    @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
    @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 */
contract ChildValidatorSet is System, Ownable {
    using Arrays for uint256[];

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
        uint256[] validatorSet;
    }

    bytes32 public constant NEW_VALIDATOR_SIG =
        0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc;
    uint256 public constant SPRINT = 64;
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100; // might want to change later!
    uint256 public constant MAX_VALIDATOR_SET_SIZE = 500;
    uint256 public constant MAX_COMMISSION = 100;
    uint256 public currentValidatorId;
    uint256 public currentEpochId;

    IStakeManager public stakeManager;
    IBLS public bls;

    uint256[2] public message;
    uint256[] public epochEndBlocks;

    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIdByAddress;
    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => mapping(uint256 => bool)) public validatorsByEpoch;
    mapping(address => bool) public whitelist;

    uint8 private initialized;

    event NewValidator(
        uint256 indexed id,
        address indexed validator,
        uint256[4] blsKey
    );

    event NewEpoch(
        uint256 indexed id,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        bytes32 epochRoot
    );

    modifier initializer() {
        require(initialized == 0, "ALREADY_INITIALIZED");
        _;
        initialized = 1;
    }

    modifier onlyStakeManager() {
        require(msg.sender == address(stakeManager), "ONLY_STAKE_MANAGER");
        _;
    }

    modifier isWhitelistedAndNotRegistered() {
        require(whitelist[msg.sender], "NOT_WHITELISTED");
        require(validatorIdByAddress[msg.sender] == 0, "ALREADY_REGISTERED");

        _;
    }

    /**
     * @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
     * @param governance Governance address to set as owner of the contract
     * @param newBls Address of BLS contract to check message signature
     * @param newMessage Message to check BLS signature at time of registration
     * @param validatorAddresses Addresses of validators
     * @param validatorPubkeys BLS pubkeys of validators
     * @param epochValidatorSet First active validator set
     */
    function initialize(
        IStakeManager newStakeManager,
        address governance,
        IBLS newBls,
        uint256[2] calldata newMessage,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys,
        uint256[] calldata validatorStakes,
        uint256[] calldata epochValidatorSet
    ) external initializer onlySystemCall {
        // slither-disable-next-line missing-zero-check
        stakeManager = newStakeManager;
        message = newMessage;
        bls = newBls;
        uint256 i = 0; // set counter to 0 assuming validatorId is currently at 0 which it should be...
        for (; i < validatorAddresses.length; i++) {
            Validator storage newValidator = validators[i + 1];
            newValidator._address = validatorAddresses[i];
            newValidator.blsKey = validatorPubkeys[i];
            newValidator.selfStake = validatorStakes[i];
            newValidator.totalStake = validatorStakes[i];
            newValidator.status = ValidatorStatus.STAKED;

            validatorIdByAddress[validatorAddresses[i]] = i + 1;
        }
        currentValidatorId = i;

        Epoch storage nextEpoch = epochs[++currentEpochId];
        nextEpoch.validatorSet = epochValidatorSet;

        _transferOwnership(governance);
    }

    /**
     * @notice Adds addresses which are allowed to register as validators.
     * @param whitelistAddreses Array of address to whitelist
     */
    function addToWhitelist(address[] calldata whitelistAddreses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            whitelist[whitelistAddreses[i]] = true;
        }
    }

    /**
     * @notice Deletes addresses which are allowed to register as validators.
     * @param whitelistAddreses Array of address to remove from whitelist
     */
    function deleteFromWhitelist(address[] calldata whitelistAddreses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            whitelist[whitelistAddreses[i]] = false;
        }
    }

    /**
     * @notice Validates BLS signature with the provided pubkey and registers validators into the set.
     * @param signature Signature to validate message against
     * @param pubkey BLS public key of validator
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey)
        external
        isWhitelistedAndNotRegistered
    {
        (bool result, bool callSuccess) = bls.verifySingle(
            signature,
            pubkey,
            message
        );
        require(callSuccess && result, "INVALID_SIGNATURE");

        whitelist[msg.sender] = false;

        uint256 currentId = ++currentValidatorId;

        Validator storage newValidator = validators[currentId];

        newValidator._address = msg.sender;
        newValidator.blsKey = pubkey;
        newValidator.status = ValidatorStatus.REGISTERED;

        validatorIdByAddress[msg.sender] = currentId;

        emit NewValidator(currentId, msg.sender, pubkey);
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
        require(
            (epoch.endBlock - epoch.startBlock + 1) % SPRINT == 0,
            "EPOCH_MUST_BE_DIVISIBLE_BY_64"
        );
        require(
            epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock,
            "INVALID_START_BLOCK"
        );

        Epoch storage newEpoch = epochs[newEpochId];
        newEpoch.endBlock = epoch.endBlock;
        newEpoch.startBlock = epoch.startBlock;
        newEpoch.epochRoot = epoch.epochRoot;

        epochEndBlocks.push(epoch.endBlock);

        _setNextValidatorSet(newEpochId + 1, epoch.epochRoot);

        stakeManager.distributeRewards(uptime);

        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    function addSelfStake(uint256 id, uint256 amount)
        external
        onlyStakeManager
    {
        Validator storage validator = validators[id];

        validator.selfStake += amount;
        validator.totalStake += amount;
    }

    function unstake(uint256 id, uint256 amount) external onlyStakeManager {
        Validator storage validator = validators[id];
        validator.selfStake -= amount;
        validator.totalStake -= amount;
    }

    function addTotalStake(uint256 id, uint256 amount)
        external
        onlyStakeManager
    {
        Validator storage validator = validators[id];

        require(validator.selfStake != 0, "DELEGATIONS_LOCKED");

        validator.totalStake += amount;
    }

    function updateValidatorStatus(uint256 id, ValidatorStatus newStatus)
        external
        onlyStakeManager
    {
        Validator storage validator = validators[id];

        validator.status = newStatus;
    }

    function setCommission(uint256 id, uint256 newCommission) external {
        Validator storage validator = validators[id];

        require(msg.sender == validator._address, "ONLY_VALIDATOR");
        require(newCommission <= MAX_COMMISSION, "INVALID_COMMISSION");

        validator.commission = newCommission;
    }

    /**
     * @notice Returns the full validator struct for a validator ID
     * @dev There is no need to use this function unless you want the validator BLS key array
     * @param id ID of the validator to return data for
     * @return Validator Returns the full validator struct if exists, or an empty struct
     */
    function getValidatorById(uint256 id)
        external
        view
        returns (Validator memory)
    {
        return validators[id];
    }

    function getCurrentValidatorSet() external view returns (uint256[] memory) {
        return epochs[currentEpochId].validatorSet;
    }

    /**
     * @notice Look up an epoch by block number. Searches in O(log n) time.
     * @param blockNumber ID of epoch to be committed
     * @return Epoch Returns epoch if found, or else, the last epoch
     */
    function getEpochByBlock(uint256 blockNumber)
        external
        view
        returns (Epoch memory)
    {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        return epochs[ret + 1];
    }

    function getValidatorStatus(uint256 id)
        external
        view
        returns (ValidatorStatus)
    {
        return validators[id].status;
    }

    /**
     * @notice Calculate validator power for a validator in percentage.
     * @return uint256 Returns validator power at 6 decimals. Therefore, a return value of 123456 is 0.123456%
     */
    function calculateValidatorPower(uint256 id)
        external
        view
        returns (uint256)
    {
        uint256 totalStake = calculateTotalStake();
        uint256 validatorStake = validators[id].totalStake;

        /* 6 decimals is somewhat arbitrary selected, but if we work backwards:
           MATIC total supply = 10 billion, smallest validator = 1997 MATIC, power comes to 0.00001997% */
        return (validatorStake * 100 * (10**6)) / totalStake;
    }

    /**
     * @notice Calculate total stake in the network (self-stake + delegation)
     * @return stake Returns total stake (in MATIC wei)
     */
    function calculateTotalStake() public view returns (uint256 stake) {
        for (uint256 i = 1; i <= currentValidatorId; i++) {
            stake += validators[i].totalStake;
        }
    }

    /**
     * @notice Sets the validator set for an epoch using the previous root as seed
     */
    function _setNextValidatorSet(uint256 epochId, bytes32 epochRoot) internal {
        uint256 currentId = currentValidatorId;
        uint256 validatorSetSize = ACTIVE_VALIDATOR_SET_SIZE;
        // if current total set is less than wanted active validator set size, we include the entire set
        if (currentId <= validatorSetSize) {
            uint256[] memory validatorSet = new uint256[](currentId); // include all validators in set
            for (uint256 i = 0; i < currentId; i++) {
                validatorSet[i] = i + 1; // validators are one-indexed
            }
            epochs[epochId].validatorSet = validatorSet;
            // else, randomly pick active validator set from total validator set
        } else {
            uint256[] memory validatorSet = new uint256[](validatorSetSize);
            uint256 counter = 0;
            for (uint256 i = 0; ; i++) {
                // use epoch root with seed and pick a random index
                uint256 randomIndex = uint256(
                    keccak256(abi.encodePacked(epochRoot, i))
                ) % currentId;
                // if validator picked, skip iteration
                if (validatorsByEpoch[epochId][randomIndex]) {
                    continue;
                    // else, add validator and include in set
                } else {
                    validatorsByEpoch[epochId][randomIndex] = true;
                    validatorSet[counter++] = randomIndex;
                }
                if (validatorSet[validatorSetSize - 1] != 0) {
                    break; // last element filled, break
                }
            }
            epochs[epochId].validatorSet = validatorSet;
        }
    }
}
