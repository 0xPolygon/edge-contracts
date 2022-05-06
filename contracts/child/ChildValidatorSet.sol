// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
    @title ChildValidatorSet
    @author Polygon Technology
    @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
    @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 */
contract ChildValidatorSet {
    struct Validator {
        uint256 id;
        address _address;
        uint256[4] blsKey;
        uint256 selfStake;
        uint256 stake; // self-stake + delegation
    }

    uint256 public currentValidatorId = 0;

    // string "polygon-v3-validator" with domain 0x59498fac6123cdfe822370ddd6dea65aadfaddbb218b583c98671a2203ef2baa
    uint256[2] public message = [
        0x09f8415678f70bc518b2993a3715be706913c5f4645c50cfe300247fcaf77d64,
        0x27df47b2126dae0e3d2a2044e64fb35dff1789d7943d2657f1ab3cd11103b7e4
    ];

    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIdByAddress;

    event NewValidator(
        uint256 indexed id,
        address indexed validator,
        uint256[4] blsKey
    );

    /**
     * @notice Constructor for ChildValidatorSet
     * @dev This is a genesis contract, the intent is to get the bytecode and directly put it in v3 client.
     */
    constructor() {
        address[4] memory validatorAddresses = [
            0xccD888026857e93F570a0b732d21DFB03e8D2f5b,
            0xC64058887a1F68B50D4262145E330c3cC794Ee1F,
            0x7bF57EC56B0fD90fc14FC2D10330aCC33Fd380A3,
            0xe0505B8945A3d3f4A882312FA2ef5c29ACEd2dCd
        ]; // arbitrary addresses
        uint256[4][4] memory validatorPubkeys = [
            [
                0x0c3467c0b9982b5a6bfdb121a2b897153e5e30a3b798d5c208303a1b8b8cffed,
                0x0c155fadc3a4c4b4807f74bd3d5145508ea66c6cf8c2fdd0448baccbd6f36513,
                0x1fd1c152cb0d6ac2b1b01458d7ddc0d0a8c0082d0e6e077752d472c990cde672,
                0x01d9699766c2a44171c03cf45c591656ee04d441b87bce7eb33e0e629bc51777
            ],
            [
                0x1054444e344c4508cca4b4917f676c6f3b2ee27ea7ef9a2ad6ff662368a58262,
                0x1df529739957e60c99399b3c5b1ff1ebb3146c42933b1874be71a16f805eb0c3,
                0x064d64838ad019d8307a7ed2e8938cb4b6d64ebe4f8b1cbbac97b64e4f571df3,
                0x126a22fc1a9e8dc9ec5319bfca0752429cd56d3afc0aed2672b50557edaee393
            ],
            [
                0x18a8ca9bf13ea0c8264ad2aa7f296854a8cab1fdd99b9c5ba37a2af181680c15,
                0x0ec2f1752d513a97cf9eebe3d67e9d3e95035889a06ece6c1e9245ef0de79840,
                0x1737dfa0726f9c3e164bcdad6ce3a491af254b50760fa208756d612ec846ddba,
                0x25ea0434b38c0b491683e0e64a7e2516e9f0f9d5403f173d2a9ca8009de53f69
            ],
            [
                0x16ff3ee83720ca822a6633ab4631538ffa3a13b54245e26d8fea74546cadcd7e,
                0x1628bd9c4c18605600ddfdcea29b7a9f15546633a09c065b4c82597fb96e4c8e,
                0x06b2473d92b99b1b2017f1ea021d91e4049099eafe4ad5412842d1a8bec63497,
                0x1454d7789b1aef3cb540bb0db89e0113c86034304169fd7b496239cede16dc04
            ]
        ]; // arbitrary pubkeys
        uint256[4] memory stakes = [
            uint256(0xfffffffffffffff),
            uint256(0xfffffffffffffff),
            uint256(0xfffffffffffffff),
            uint256(0xfffffffffffffff)
        ]; // arbitrary stakes
        uint256 currentId = 0; // set counter to 0 assuming validatorId is currently at 0 which it should be...
        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            Validator storage newValidator = validators[++currentId];
            newValidator.id = currentId;
            newValidator._address = validatorAddresses[i];
            newValidator.blsKey = validatorPubkeys[i];
            newValidator.selfStake = stakes[i];
            newValidator.stake = stakes[i];

            validatorIdByAddress[validatorAddresses[i]] = currentId;
        }
        currentValidatorId = currentId;
    }
}
