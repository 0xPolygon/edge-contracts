// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IBLS {
    function verifySingle(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    ) external view returns (bool, bool);
}

/**
    @title RootValidatorSet
    @author Polygon Technology
    @notice Validator set contract for Polygon PoS v3. This contract serves the purpose of validator registration.
    @dev The contract is used to onboard new validators and register their ECDSA and BLS public keys.
 */
contract RootValidatorSet is Initializable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Validator {
        uint256 id;
        address ethAddress;
        uint256[4] blsKey;
    }

    uint256 public currentValidatorId;
    IBLS public bls;

    uint256[2] public message;
    mapping(uint256 => Validator) public validators;

    EnumerableSet.AddressSet private whitelist;

    event NewValidator(uint256 indexed id, address indexed validator);

    modifier isWhitelisted(address _address) {
        require(whitelist.contains(_address), "NOT_WHITELISTED");

        _;
    }

    /**
     * @notice Initialization function for RootValidatorSet
     * @dev Contract can only be initialized once, also transfers ownership to initializing address.
     * @param _bls Address of the BLS library contract.
     * @param _validators Array of validators to seed the contract with.
     * @param _message Signed message to verify with BLS.
     */
    function initialize(
        IBLS _bls,
        Validator[] calldata _validators,
        uint256[2] calldata _message
    ) external initializer {
        bls = _bls;
        for (uint256 i = 0; i < _validators.length; i++) {
            validators[currentValidatorId++] = _validators[i];
        }
        message = _message;
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Adds addresses which are allowed to register as validators.
     * @param _whitelisted Array of address to whitelist
     */
    function addToWhitelist(address[] calldata _whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelist.add(_whitelisted[i]);
        }
    }

    /**
     * @notice Validates BLS signature with the provided pubkey and registers validators into the set.
     * @param signature Signature to validate message against
     * @param pubkey BLS public key of validator
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey)
        external
        isWhitelisted(msg.sender)
    {
        (bool result, bool callSuccess) = bls.verifySingle(
            signature,
            pubkey,
            message
        );
        require(callSuccess && result, "INVALID_SIGNATURE");
        Validator storage newValidator = validators[currentValidatorId];
        newValidator.id = currentValidatorId++;
        newValidator.ethAddress = msg.sender;
        newValidator.blsKey = pubkey;

        emit NewValidator(currentValidatorId - 1, msg.sender);
    }
}
