// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Arrays.sol";

interface IStateReceiver {
    function onStateReceive(
        uint256 id,
        address sender,
        bytes calldata data
    ) external;
}

/**
    @title ChildValidatorSet
    @author Polygon Technology
    @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
    @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 */
contract ChildValidatorSet is IStateReceiver {
    using Arrays for uint256[];

    struct Validator {
        uint256 id;
        address _address;
        uint256[4] blsKey;
        uint256 selfStake;
        uint256 stake; // self-stake + delegation, store delegation separately?
    }

    struct Epoch {
        uint256 id;
        uint256 startBlock;
        uint256 endBlock;
        bytes32 epochRoot;
        uint256[] validatorSet;
    }

    bytes32 public constant NEW_VALIDATOR_SIG =
        0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc;
    uint256 public constant SPRINT = 64;
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100; // might want to change later!
    uint256 public currentValidatorId;
    uint256 public currentEpochId;
    address public rootValidatorSet;

    uint256[] public epochEndBlocks;

    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIdByAddress;
    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => mapping(uint256 => bool)) public validatorsByEpoch;

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
        // OZ initializer is too bulky...
        require(initialized == 0, "ALREADY_INITIALIZED");
        _;
        initialized = 1;
    }

    modifier onlySystemCall() {
        require(
            msg.sender == 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE,
            "ONLY_SYSTEMCALL"
        );
        _;
    }

    /**
     * @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
     * @param validatorAddresses Addresses of validators
     * @param validatorPubkeys BLS pubkeys of validators
     * @param epochValidatorSet First active validator set
     */
    function initialize(
        address newRootValidatorSet,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys,
        uint256[] calldata validatorStakes,
        uint256[] calldata epochValidatorSet
    ) external initializer onlySystemCall {
        rootValidatorSet = newRootValidatorSet;
        uint256 currentId = 0; // set counter to 0 assuming validatorId is currently at 0 which it should be...
        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            Validator storage newValidator = validators[++currentId];
            newValidator.id = currentId;
            newValidator._address = validatorAddresses[i];
            newValidator.blsKey = validatorPubkeys[i];
            newValidator.selfStake = validatorStakes[i];
            newValidator.stake = validatorStakes[i];

            validatorIdByAddress[validatorAddresses[i]] = currentId;
        }
        currentValidatorId = currentId;

        Epoch storage nextEpoch = epochs[++currentEpochId];
        nextEpoch.validatorSet = epochValidatorSet;
    }

    /**
     * @notice Allows the v3 client to commit epochs to this contract.
     * @param id ID of epoch to be committed
     * @param startBlock First block in epoch
     * @param endBlock Last block in epoch
     */
    function commitEpoch(
        uint256 id,
        uint256 startBlock,
        uint256 endBlock,
        bytes32 epochRoot
    ) external onlySystemCall {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(endBlock > startBlock, "NO_BLOCKS_COMMITTED");
        require((endBlock - startBlock + 1) % SPRINT == 0, "INCOMPLETE_SPRINT");
        require(
            epochs[newEpochId - 1].endBlock < startBlock,
            "BLOCK_IN_COMMITTED_EPOCH"
        );

        Epoch storage newEpoch = epochs[newEpochId];
        newEpoch.id = newEpochId;
        newEpoch.endBlock = endBlock;
        newEpoch.startBlock = startBlock;
        newEpoch.epochRoot = epochRoot;

        epochEndBlocks.push(endBlock);

        setNextValidatorSet(newEpochId + 1, epochRoot);

        emit NewEpoch(id, startBlock, endBlock, epochRoot);
    }

    // function modifyValidatorSetSize(uint256 _newSize) external onlySystemCall {
    //     activeValidatorSetSize = _newSize;
    // }

    /**
     * @notice Enables the RootValidatorSet to trustlessly update validator set on child chain.
     * @param data Data received from RootValidatorSet
     */
    function onStateReceive(
        uint256, /* id */
        address sender,
        bytes calldata data
    ) external {
        // slither-disable-next-line too-many-digits
        require(
            msg.sender == 0x0000000000000000000000000000000000001001,
            "ONLY_STATESYNC"
        );
        require(sender == rootValidatorSet, "ONLY_ROOT");
        (bytes32 signature, bytes memory decodedData) = abi.decode(
            data,
            (bytes32, bytes)
        );
        require(signature == NEW_VALIDATOR_SIG, "INVALID_SIGNATURE");
        (uint256 id, address _address, uint256[4] memory blsKey) = abi.decode(
            decodedData,
            (uint256, address, uint256[4])
        );

        Validator storage newValidator = validators[id];
        newValidator.id = id;
        newValidator._address = _address;
        newValidator.blsKey = blsKey;

        validatorIdByAddress[_address] = id;

        currentValidatorId++; // we assume statesyncs are strictly ordered

        emit NewValidator(id, _address, blsKey);
    }

    function getCurrentValidatorSet() external view returns (uint256[] memory) {
        return epochs[currentEpochId].validatorSet;
    }

    /**
     * @notice Look up an epoch by block number. Searches in O(log n) time.
     * @param blockNumber ID of epoch to be committed
     * @return bool Returns true if the search was successful, else false
     * @return Epoch Returns epoch if found, or else, the last epoch
     */
    function getEpochByBlock(uint256 blockNumber)
        external
        view
        returns (bool, Epoch memory)
    {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        if (ret == epochEndBlocks.length) {
            return (false, epochs[currentEpochId]);
        } else {
            return (true, epochs[ret + 1]);
        }
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
        uint256 validatorStake = validators[id].stake;
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
            stake += validators[i].stake;
        }
    }

    /**
     * @notice Sets the validator set for an epoch using the previous root as seed
     */
    function setNextValidatorSet(uint256 epochId, bytes32 epochRoot) internal {
        uint256 currentId = currentValidatorId;
        uint256 validatorSetSize = ACTIVE_VALIDATOR_SET_SIZE;
        if (currentId <= validatorSetSize) {
            uint256[] memory validatorSet = new uint256[](currentId); // include all validators in set
            for (uint256 i = 0; i < currentId; i++) {
                validatorSet[i] = i + 1; // validators are one-indexed
            }
            epochs[epochId].validatorSet = validatorSet;
        } else {
            uint256[] memory validatorSet = new uint256[](validatorSetSize);
            uint256 counter = 0;
            for (uint256 i = 0; ; i++) {
                uint256 randomIndex = uint256(
                    keccak256(abi.encodePacked(epochRoot, i))
                ) % currentId;
                if (validatorsByEpoch[epochId][randomIndex]) {
                    continue;
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
