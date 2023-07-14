// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @title IValdiatorSets
    @author ConsenSys
    */
interface IValidatorSets {
    struct Validator {
        address _address;
        uint256[4] blsKey;
        uint256 votingPower;
    }
}
