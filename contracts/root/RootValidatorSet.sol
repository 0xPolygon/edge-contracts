// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
    struct Validator {
        uint256 id;
        address _address;
        uint256[4] blsKey;
    }

    uint256 public currentValidatorId = 0;
    IBLS public bls;

    uint256[2] public message;
    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIdByAddress;
    mapping(address => bool) public whitelist;

    event NewValidator(
        uint256 indexed id,
        address indexed validator,
        uint256[4] blsKey
    );

    modifier isWhitelistedAndNotRegistered() {
        require(whitelist[msg.sender], "NOT_WHITELISTED");
        require(validatorIdByAddress[msg.sender] == 0, "ALREADY_REGISTERED");

        _;
    }

    /**
     * @notice Initialization function for RootValidatorSet
     * @dev Contract can only be initialized once, also transfers ownership to initializing address.
     * @param newBls Address of the BLS library contract.
     * @param validatorAddresses Array of validator addresses to seed the contract with.
     * @param validatorAddresses Array of validator pubkeys to seed the contract with.
     * @param newMessage Signed message to verify with BLS.
     */
    function initialize(
        IBLS newBls,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys,
        uint256[2] calldata newMessage
    ) external initializer {
        require(
            validatorAddresses.length == validatorPubkeys.length,
            "LENGTH_MISMATCH"
        );
        bls = newBls;
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
        message = newMessage;
        _transferOwnership(msg.sender);
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
        newValidator.id = currentId;
        newValidator._address = msg.sender;
        newValidator.blsKey = pubkey;
        validatorIdByAddress[msg.sender] = currentId;

        emit NewValidator(currentId, msg.sender, pubkey);
    }
}
