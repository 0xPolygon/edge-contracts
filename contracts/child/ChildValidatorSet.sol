// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
    @title ChildValidatorSet
    @author Polygon Technology
    @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
    @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 */
contract ChildValidatorSet is Initializable {
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
    mapping(uint256 => uint256) public epochIdByBlock;

    event NewValidator(
        uint256 indexed id,
        address indexed validator,
        uint256[4] blsKey
    );

    event NewEpoch(
        uint256 indexed id,
        uint256 indexed startBlock,
        uint256 indexed endBlock
    )

    /**
     * @notice Constructor for ChildValidatorSet
     * @dev This is a genesis contract, the intent is to get the bytecode and directly put it in v3 client.
     */
    constructor() {

    }

    modifier onlySystemCall() {
        require(msg.sender == 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE, "ONLY_SYSTEMCALL");
        _;
    }

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

        emit NewEpoch(id, startBlock, endBlock);
    }
}
