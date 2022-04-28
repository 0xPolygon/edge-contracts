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

contract EthereumValidatorSet is Initializable, Ownable {
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

    function addToWhitelist(address[] calldata _whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelist.add(_whitelisted[i]);
        }
    }

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
