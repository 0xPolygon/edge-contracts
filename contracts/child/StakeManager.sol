// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Initializable} from "../libs/Initializable.sol";
import {System} from "./System.sol";

interface IChildValidatorSet {
    struct Validator {
        address _address;
        //uint256[4] blsKey; // default mapping function does not return array
        uint256 selfStake;
        uint256 totalStake; // self-stake + delegation
    }

    struct Epoch {
        uint256 startBlock;
        uint256 endBlock;
        bytes32 epochRoot;
        uint256[] validatorSet;
    }

    function addSelfStake(uint256 id, uint256 amount) external;

    function addTotalStake(uint256 id, uint256 amount) external;

    function activeValidatorSetSize() external view returns (uint256);

    function calculateValidatorPower(uint256 id)
        external
        view
        returns (uint256);

    function validators(uint256 id) external view returns (Validator memory);

    function epochs(uint256 id) external view returns (Epoch memory);
}

contract StakeManager is System, Initializable {
    struct Uptime {
        uint256[] ids;
        uint256[] uptimes;
        uint256 totalUptime;
    }

    uint256 public epochReward;
    uint256 public lastRewardedEpochId;
    uint256 public minSelfStake;
    uint256 public minDelegation;
    IChildValidatorSet public childValidatorSet;

    mapping(address => uint256) public validatorRewards;
    mapping(address => uint256) public delegatorRewards;
    mapping(uint256 => uint256) public selfStakes;

    modifier onlyValidatorSet() {
        require(msg.sender == address(childValidatorSet), "ONLY_VALIDATOR_SET");

        _;
    }

    function initialize(
        uint256 newEpochReward,
        uint256 newMinSelfStake,
        uint256 newMinDelegation,
        IChildValidatorSet newChildValidatorSet
    ) external initializer {
        epochReward = newEpochReward;
        minSelfStake = newMinSelfStake;
        minDelegation = newMinDelegation;
        childValidatorSet = newChildValidatorSet;
    }

    function distributeRewards(
        uint256 epochId,
        Uptime calldata uptime,
        bytes calldata signature
    ) external onlyValidatorSet {
        bytes32 hash = keccak256(abi.encode(uptime));

        _checkPubkeyAggregation(hash, signature);

        require(epochId == lastRewardedEpochId + 1, "INVALID_EPOCH_ID");

        uint256 length = uptime.ids.length;

        require(length == uptime.uptimes.length, "LENGTH_MISMATCH");

        uint256[] memory weights;
        uint256 aggStake = 0;
        uint256 aggWeight = 0;

        for (uint256 i = 0; i < length; i++) {
            uint256 power = childValidatorSet.calculateValidatorPower(
                uptime.ids[i]
            );
            aggStake += power;
            weights[i] = uptime.uptimes[i] * power;
            aggWeight += weights[i];
        }

        require(aggStake > (66 * (10**6)), "NOT_ENOUGH_CONSENSUS");

        uint256 reward = epochReward;

        reward = (reward * aggStake) / (100 * (10**6)); // scale reward to power staked

        for (uint256 i = 0; i < length; i++) {
            IChildValidatorSet.Validator memory validator = childValidatorSet
                .validators(uptime.ids[i]);
            validatorRewards[validator._address] +=
                (reward * weights[i]) /
                aggWeight;
        }
    }

    function selfStake(uint256 id) external payable {
        require(msg.value >= minSelfStake, "STAKE_TOO_LOW");

        IChildValidatorSet.Validator memory validator = childValidatorSet
            .validators(id);

        require(msg.sender == validator._address, "INVALID_SENDER");

        childValidatorSet.addSelfStake(id, msg.value);
    }

    function delegate(uint256 id) external payable {
        require(msg.value >= minDelegation, "DELEGATION_TOO_LOW");

        childValidatorSet.addTotalStake(id, msg.value);
    }

    function _checkPubkeyAggregation(bytes32 message, bytes calldata signature)
        internal
        view
    {
        // verify signatures for provided sig data and sigs bytes
        // solhint-disable-next-line avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (
            bool callSuccess,
            bytes memory returnData
        ) = VALIDATOR_PKCHECK_PRECOMPILE.staticcall{
                gas: VALIDATOR_PKCHECK_PRECOMPILE_GAS
            }(abi.encode(message, signature));
        bool verified = abi.decode(returnData, (bool));
        require(callSuccess && verified, "SIGNATURE_VERIFICATION_FAILED");
    }
}
