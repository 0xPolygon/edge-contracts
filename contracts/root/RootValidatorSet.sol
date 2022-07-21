// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBLS.sol";

/**
    @title RootValidatorSet
    @author Polygon Technology
    @notice Validator set contract for Polygon PoS v3. This contract serves the purpose of validator registration.
    @dev The contract is used to onboard new validators and register their ECDSA and BLS public keys.
 */
// slither-disable-next-line missing-inheritance
contract RootValidatorSet is Initializable, Ownable {
    struct Validator {
        uint256 id;
        address _address;
        uint256[4] blsKey;
    }

    uint256 public currentValidatorId;
    address public checkpointManager;

    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIdByAddress;

    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100;

    event NewValidator(
        uint256 indexed id,
        address indexed validator,
        uint256[4] blsKey
    );

    /**
     * @notice Initialization function for RootValidatorSet
     * @dev Contract can only be initialized once, also transfers ownership to initializing address.
     * @param validatorAddresses Array of validator addresses to seed the contract with.
     * @param validatorAddresses Array of validator pubkeys to seed the contract with.
     */
    function initialize(
        address governance,
        address newCheckpointManager,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys
    ) external initializer {
        require(
            validatorAddresses.length == validatorPubkeys.length,
            "LENGTH_MISMATCH"
        );
        // slither-disable-next-line missing-zero-check
        checkpointManager = newCheckpointManager;
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
        _transferOwnership(governance);
    }

    function addValidator(Validator[] calldata newValidators) external {
        require(msg.sender == checkpointManager, "ONLY_CHECKPOINT_MANAGER");
        uint256 length = newValidators.length;
        uint256 currentId = currentValidatorId;
        for (uint256 i = 0; i < length; i++) {
            validators[i + currentId + 1] = newValidators[i];
        }
    }

    function getValidator(uint256 id) external view returns (Validator memory) {
        return validators[id];
    }

    function getValidatorBlsKey(uint256 id)
        external
        view
        returns (uint256[4] memory)
    {
        return validators[id].blsKey;
    }

    function activeValidatorSetSize() external view returns (uint256) {
        if (currentValidatorId < ACTIVE_VALIDATOR_SET_SIZE) {
            return currentValidatorId;
        } else {
            return ACTIVE_VALIDATOR_SET_SIZE;
        }
    }
}
