// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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

    function validatorIdByAddress(address _address)
        external
        view
        returns (uint256);

    function currentEpochId() external view returns (uint256);

    function currentValidatorId() external view returns (uint256);

    function activeValidatorSetSize() external view returns (uint256);

    function calculateValidatorPower(uint256 id)
        external
        view
        returns (uint256);

    function validators(uint256 id) external view returns (Validator memory);

    function epochs(uint256 id) external view returns (Epoch memory);
}

contract StakeManager is System, Initializable, ReentrancyGuard {
    struct Uptime {
        uint256 epochId;
        uint256[] ids;
        uint256[] uptimes;
        uint256 totalUptime;
    }

    struct Delegation {
        uint256 epochId;
        uint256 amount;
    }

    uint256 public constant REWARD_PRECISION = 10**18;

    uint256 public epochReward;
    uint256 public lastRewardedEpochId;
    uint256 public minSelfStake;
    uint256 public minDelegation;
    IChildValidatorSet public childValidatorSet;

    mapping(uint256 => mapping(uint256 => uint256)) public validatorRewards; // validator id -> epoch -> amount
    mapping(uint256 => mapping(uint256 => uint256)) public rewardShares; // epoch -> validatorId -> reward per share
    mapping(address => mapping(uint256 => Delegation)) public delegations; // user address -> validator id -> Delegation

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

    function distributeRewards(Uptime calldata uptime, bytes calldata signature)
        external
        onlySystemCall
    {
        bytes32 hash = keccak256(abi.encode(uptime));

        _checkPubkeyAggregation(hash, signature);

        require(uptime.epochId == lastRewardedEpochId + 1, "INVALID_EPOCH_ID");
        require(
            uptime.epochId < childValidatorSet.currentEpochId(),
            "EPOCH_NOT_COMMITTED"
        );

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
            require(validator._address != address(0), "INVALID_VALIDATOR_ID");
            uint256 validatorReward = (reward * weights[i]) / aggWeight;
            validatorRewards[uptime.ids[i]][uptime.epochId] = validatorReward;
            rewardShares[uptime.epochId][uptime.ids[i]] =
                (validatorReward * REWARD_PRECISION) /
                validator.totalStake;
        }
    }

    function selfStake() external payable {
        require(msg.value >= minSelfStake, "STAKE_TOO_LOW");

        uint256 id = childValidatorSet.validatorIdByAddress(msg.sender);

        require(id != 0, "INVALID_SENDER");

        childValidatorSet.addSelfStake(id, msg.value);
    }

    function delegate(uint256 id) external payable {
        require(msg.value >= minDelegation, "DELEGATION_TOO_LOW");

        require(
            id < childValidatorSet.currentValidatorId(),
            "INVALID_VALIDATOR_ID"
        );

        Delegation storage delegation = delegations[msg.sender][id];

        delegation.epochId = childValidatorSet.currentEpochId() - 1;

        // calculate previous reward and add

        delegation.amount += msg.value;

        childValidatorSet.addTotalStake(id, msg.value);
    }

    function claimDelegatorReward(uint256 id) external payable nonReentrant {
        uint256 reward = calculateDelegatorReward(id, msg.sender);

        Delegation storage delegation = delegations[msg.sender][id];

        delegation.epochId = lastRewardedEpochId;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: reward}("");

        require(success, "TRANSFER_FAILED");
    }

    function calculateDelegatorReward(uint256 id, address delegator)
        public
        view
        returns (uint256)
    {
        Delegation memory delegation = delegations[delegator][id];

        uint256 startIndex = delegation.epochId;
        uint256 endIndex = lastRewardedEpochId;

        uint256 totalReward = 0;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            totalReward += delegation.amount * rewardShares[startIndex][id];
        }

        return totalReward / REWARD_PRECISION;
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
