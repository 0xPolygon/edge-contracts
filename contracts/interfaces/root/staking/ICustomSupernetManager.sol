// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../root/staking/lib/GenesisLib.sol";

struct Validator {
    uint256[4] blsKey;
    uint256 stake;
    bool isWhitelisted;
    bool isActive;
}

interface ICustomSupernetManager {
    event AddedToWhitelist(address indexed validator);
    event RemovedFromWhitelist(address indexed validator);
    event ValidatorRegistered(address indexed validator, uint256[4] blsKey);
    event ValidatorDeactivated(address validator);

    error Unauthorized(string message);
    error InvalidSignature(address validator);

    /// @notice Allows to whitelist validators that are allowed to stake
    /// @dev only callable by owner
    function whitelistValidators(address[] calldata validators_) external;

    /// @notice registers the public key of a validator
    function register(address validator_, uint256[2] calldata signature, uint256[4] calldata pubkey) external;

    /// @notice finalizes initial genesis validator set
    /// @dev only callable by owner
    function finalizeGenesis() external;

    /// @notice enables staking after successful initialisation of the child chain
    /// @dev only callable by owner
    function enableStaking() external;

    /// @notice Withdraws slashed MATIC of slashed validators
    /// @dev only callable by owner
    function withdrawSlashedStake(address to) external;

    /// @notice called by the exit helpers to either release the stake of a validator or slash it
    function onL2StateReceive(uint256 /*id*/, address sender, bytes calldata data) external;

    /// @notice returns the genesis validator set with their balances
    function genesisSet() external view returns (GenesisValidator[] memory);

    /// @notice returns validator instance based on provided address
    function getValidator(address validator_) external view returns (Validator memory);
}
