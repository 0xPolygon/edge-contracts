// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

/**
    @title ChildValidatorSet
    @author Polygon Technology
    @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
    @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 */
contract ChildValidatorSet is Initializable {
    using Arrays for uint256[];
    struct Validator {
        uint256 id;
        address _address;
        uint256[4] blsKey;
        uint256 selfStake;
        uint256 stake; // self-stake + delegation
    }

    struct Epoch {
        uint256 id;
        uint256 startBlock;
        uint256 endBlock;
    }

    uint256 constant public SPRINT = 64;
    uint256 public currentValidatorId;
    uint256 public currentEpochId;

    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIdByAddress;
    mapping(uint256 => Epoch) public epochs;
    uint256[] public epochEndBlocks;

    event NewValidator(
        uint256 indexed id,
        address indexed validator,
        uint256[4] blsKey
    );

    event NewEpoch(
        uint256 indexed id,
        uint256 indexed startBlock,
        uint256 indexed endBlock
    );

    modifier onlySystemCall() {
        require(msg.sender == 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE, "ONLY_SYSTEMCALL");
        _;
    }

    /**
     * @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
     * @param validatorAddresses Addresses of validators
     * @param validatorPubkeys BLS pubkeys of validators
     */
    function initialize(
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys
    ) external initializer onlySystemCall {
        require(
            validatorAddresses.length == validatorPubkeys.length,
            "LENGTH_MISMATCH"
        );
        uint256 currentId = 0; // set counter to 0 assuming validatorId is currently at 0 which it should be...
        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            Validator storage newValidator = validators[++currentId];
            newValidator.id = currentId;
            newValidator._address = validatorAddresses[i];
            newValidator.blsKey = validatorPubkeys[i];

            validatorIdByAddress[validatorAddresses[i]] = currentId;

            emit NewValidator(
                currentId,
                validatorAddresses[i],
                validatorPubkeys[i]
            );
        }
        currentValidatorId = currentId;
    }

    /**
     * @notice Allows the v3 client to commit epochs to this contract.
     * @param id ID of epoch to be committed
     * @param startBlock First block in epoch
     * @param endBlock Last block in epoch
     */
    function commitEpoch(uint256 id, uint256 startBlock, uint256 endBlock) external onlySystemCall {
        uint256 newEpochId = ++currentEpochId;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(endBlock > startBlock, "NO_BLOCKS_COMMITTED");
        require((endBlock - startBlock + 1) % SPRINT == 0, "INCOMPLETE_SPRINT");
        require(epochs[currentEpochId].endBlock < startBlock, "BLOCK_IN_COMMITTED_EPOCH");

        Epoch storage newEpoch = epochs[newEpochId];
        newEpoch.id = newEpochId;
        newEpoch.endBlock = endBlock;
        newEpoch.startBlock = startBlock;

        epochEndBlocks.push(endBlock);

        emit NewEpoch(id, startBlock, endBlock);
    }

    /**
     * @notice Look up an epoch by block number. Searches in O(log n) time.
     * @param blockNumber ID of epoch to be committed
     * @return bool Returns true if the search was successful, else false
     * @return Epoch Returns epoch if found, or else, the last epoch
     */
    function getEpochByBlock(uint256 blockNumber) external view returns (bool, Epoch memory) {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        if (ret == epochEndBlocks.length) {
            return (false, epochs[currentEpochId]);
        } else {
            return (true, epochs[ret]);
        }
    }
}
