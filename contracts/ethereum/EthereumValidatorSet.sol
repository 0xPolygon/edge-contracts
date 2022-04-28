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

	uint256 currentValidatorId;
	uint256[2] message;
	mapping(uint256 => Validator) validators;
	EnumerableSet.AddressSet whitelist;

	modifier isWhitelisted(address _address) {
		require(whitelist.contains(_address), "NOT_WHITELISTED");

		_;
	}

	function initialize(Validator[] calldata _validators, uint256[2] calldata _message) external initializer {
		for (uint256 i = 0; i < _validators.length; i++) {
			validators[currentValidatorId++] = _validators[i];
		}
		message = _message;
		_transferOwnership(msg.sender);
 	}

 	function addToWhitelist(address[] calldata _whitelisted) external {
 		for (uint256 i = 0; i < _whitelisted.length; i++) {
 			whitelist.add(_whitelisted[i]);
 		}
 	}

 	function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external isWhitelisted(msg.sender) {

 	}
 }
