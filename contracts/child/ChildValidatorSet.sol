// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IChildValidatorSetBase.sol";
import "./modules/CVSStorage.sol";
import "./modules/CVSAccessControl.sol";
import "./modules/CVSWithdrawal.sol";
import "./modules/CVSStaking.sol";
import "./modules/CVSDelegation.sol";
import "./System.sol";

import "../libs/ValidatorStorage.sol";
import "../libs/ValidatorQueue.sol";
import "../libs/SafeMathInt.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";

// solhint-disable max-states-count
contract ChildValidatorSet is
    IChildValidatorSetBase,
    CVSStorage,
    CVSAccessControl,
    CVSWithdrawal,
    CVSStaking,
    CVSDelegation,
    System
{
    using ValidatorStorageLib for ValidatorTree;
    using ValidatorQueueLib for ValidatorQueue;
    using WithdrawalQueueLib for WithdrawalQueue;
    using RewardPoolLib for RewardPool;
    using SafeMathInt for int256;
    using ArraysUpgradeable for uint256[];

    // more granular commission?
    uint256 public constant DOUBLE_SIGNING_SLASHING_PERCENT = 10;
    // epochNumber -> roundNumber -> validator address -> bool
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public doubleSignerSlashes;

    /**
     * @notice Initializer function for genesis contract, called by v3 client at genesis to set up the initial set.
     * @dev only callable by client, can only be called once
     * @param init: newEpochReward reward for a proposed epoch
     *              newMinStake minimum stake to become a validator
     *              newMinDelegation minimum amount to delegate to a validator
     * @param validatorAddresses addresses of initial validators
     * @param validatorPubkeys uint256[4] BLS public keys of initial validators
     * @param validatorStakes amount staked per initial validator
     * @param newBls address pf BLS contract/precompile
     * @param newMessage message for BLS signing
     * @param governance Governance address to set as owner of the contract
     */
    function initialize(
        InitStruct calldata init,
        address[] calldata validatorAddresses,
        uint256[4][] calldata validatorPubkeys,
        uint256[] calldata validatorStakes,
        IBLS newBls,
        uint256[2] calldata newMessage,
        address governance
    ) external initializer onlySystemCall {
        currentEpochId = 1;
        epochSize = init.epochSize;
        _transferOwnership(governance);
        __ReentrancyGuard_init();

        // slither-disable-next-line events-maths
        epochReward = init.epochReward;
        minStake = init.minStake;
        minDelegation = init.minDelegation;

        for (uint256 i = 0; i < validatorAddresses.length; i++) {
            _addToWhitelist(validatorAddresses[i]);
            Validator memory validator = Validator({
                blsKey: validatorPubkeys[i],
                stake: validatorStakes[i],
                commission: 0,
                withdrawableRewards: 0,
                active: true
            });
            _validators.insert(validatorAddresses[i], validator);
        }
        bls = newBls;
        message = newMessage;
    }

    /**
     * @inheritdoc IChildValidatorSetBase
     */
    function commitEpoch(
        uint256 id,
        Epoch calldata epoch,
        Uptime calldata uptime
    ) external onlySystemCall {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(epoch.endBlock > epoch.startBlock, "NO_BLOCKS_COMMITTED");
        require((epoch.endBlock - epoch.startBlock + 1) % epochSize == 0, "EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
        require(epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock, "INVALID_START_BLOCK");

        Epoch storage newEpoch = epochs[newEpochId];
        newEpoch.endBlock = epoch.endBlock;
        newEpoch.startBlock = epoch.startBlock;
        newEpoch.epochRoot = epoch.epochRoot;

        epochEndBlocks.push(epoch.endBlock);

        _distributeRewards(uptime);
        _processQueue();

        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    /**
     * @inheritdoc IChildValidatorSetBase
     */
    function commitEpochWithDoubleSignerSlashing(
        uint256 curEpochId,
        Epoch calldata epoch,
        Uptime calldata uptime,
        uint256 blockNumber,
        uint256 pbftRound,
        uint256 epochId,
        DoubleSignerSlashingInput[] calldata inputs
    ) external {
        uint256 length = inputs.length;
        require(length >= 2, "INVALID_LENGTH");
        // first, assert all blockhashes are unique
        require(_assertUniqueBlockhash(inputs), "BLOCKHASH_NOT_UNIQUE");

        // check aggregations are signed appropriately
        for (uint256 i = 0; i < length; i++) {
            _checkPubkeyAggregation(
                keccak256(abi.encode(blockNumber, pbftRound, epochId, inputs[i].blockHash)),
                inputs[i].bitmap,
                inputs[i].signature
            );
        }

        // get full validator set
        uint256 validatorSetLength = _validators.count;
        address[] memory validatorSet = sortedValidators(validatorSetLength);
        bool[] memory slashingSet = new bool[](validatorSetLength);

        for (uint256 i = 0; i < validatorSetLength; i++) {
            uint256 count = 0;
            for (uint256 j = 0; j < length; j++) {
                // check if bitmap index has validator
                if (_getValueFromBitmap(inputs[j].bitmap, i)) {
                    count++;
                }

                // slash validators that have signed multiple blocks
                if (count > 1) {
                    _slashDoubleSigner(validatorSet[i], epochId, pbftRound);
                    slashingSet[i] = true;
                    break;
                }
            }
        }
        _endEpochOnSlashingEvent(curEpochId, epoch, uptime, slashingSet);
    }

    /**
     * @inheritdoc IChildValidatorSetBase
     */
    function getCurrentValidatorSet() external view returns (address[] memory) {
        return sortedValidators(ACTIVE_VALIDATOR_SET_SIZE);
    }

    /**
     * @inheritdoc IChildValidatorSetBase
     */
    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory) {
        uint256 ret = epochEndBlocks.findUpperBound(blockNumber);
        return epochs[ret + 1];
    }

    /**
     * @inheritdoc IChildValidatorSetBase
     */
    function totalActiveStake() public view returns (uint256 activeStake) {
        uint256 length = ACTIVE_VALIDATOR_SET_SIZE <= _validators.count ? ACTIVE_VALIDATOR_SET_SIZE : _validators.count;
        if (length == 0) return 0;

        address tmpValidator = _validators.last();
        activeStake += getValidator(tmpValidator).stake + _validators.getDelegationPool(tmpValidator).supply;

        for (uint256 i = 1; i < length; i++) {
            tmpValidator = _validators.prev(tmpValidator);
            activeStake += getValidator(tmpValidator).stake + _validators.getDelegationPool(tmpValidator).supply;
        }
    }

    function _distributeRewards(Uptime calldata uptime) internal {
        require(uptime.epochId == currentEpochId - 1, "EPOCH_NOT_COMMITTED");

        uint256 length = uptime.uptimeData.length;

        require(length <= ACTIVE_VALIDATOR_SET_SIZE && length <= _validators.count, "INVALID_LENGTH");

        uint256 activeStake = totalActiveStake();
        uint256 reward = epochReward;

        for (uint256 i = 0; i < length; ++i) {
            UptimeData memory uptimeData = uptime.uptimeData[i];
            Validator storage validator = _validators.get(uptimeData.validator);
            uint256 validatorReward = (reward *
                (validator.stake + _validators.getDelegationPool(uptimeData.validator).supply) *
                uptimeData.signedBlocks) / (activeStake * uptime.totalBlocks);
            (uint256 validatorShares, uint256 delegatorShares) = _calculateValidatorAndDelegatorShares(
                uptimeData.validator,
                validatorReward
            );
            _distributeValidatorReward(uptimeData.validator, validatorShares);
            _distributeDelegatorReward(uptimeData.validator, delegatorShares);
        }
    }

    function _processQueue() internal {
        QueuedValidator[] storage queue = _queue.get();
        for (uint256 i = 0; i < queue.length; ++i) {
            QueuedValidator memory item = queue[i];
            address validatorAddr = item.validator;
            // values will be zero for non existing validators
            Validator storage validator = _validators.get(validatorAddr);
            // if validator already present in tree, remove and reinsert to maintain sort
            if (_validators.exists(validatorAddr)) {
                _validators.remove(validatorAddr);
            }
            validator.stake = (int256(validator.stake) + item.stake).toUint256Safe();
            _validators.insert(validatorAddr, validator);
            _queue.resetIndex(validatorAddr);
        }
        _queue.reset();
    }

    function _slashDoubleSigner(
        address key,
        uint256 epoch,
        uint256 pbftRound
    ) private {
        if (doubleSignerSlashes[epoch][pbftRound][key]) {
            return;
        }
        doubleSignerSlashes[epoch][pbftRound][key] = true;
        Validator storage validator = _validators.get(key);
        _validators.delegationPools[key].underlyingSupply -=
            (_validators.delegationPools[key].underlyingSupply * DOUBLE_SIGNING_SLASHING_PERCENT) /
            100;
        uint256 slashedAmount = (validator.stake * DOUBLE_SIGNING_SLASHING_PERCENT) / 100;
        validator.stake -= slashedAmount;
        _validators.totalStake -= slashedAmount;
        emit DoubleSignerSlashed(key, epoch, pbftRound);
    }

    function _endEpochOnSlashingEvent(
        uint256 id,
        Epoch calldata epoch,
        Uptime calldata uptime,
        bool[] memory slashingSet
    ) private {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(epoch.endBlock > epoch.startBlock, "NO_BLOCKS_COMMITTED");
        require(epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock, "INVALID_START_BLOCK");

        Epoch storage newEpoch = epochs[newEpochId];
        newEpoch.endBlock = epoch.endBlock;
        newEpoch.startBlock = epoch.startBlock;
        newEpoch.epochRoot = epoch.epochRoot;

        epochEndBlocks.push(epoch.endBlock);

        uint256 length = uptime.uptimeData.length;

        require(length <= ACTIVE_VALIDATOR_SET_SIZE && length <= _validators.count, "INVALID_LENGTH");

        uint256 activeStake = totalActiveStake();
        uint256 reward = (epochReward * (epoch.endBlock - epoch.startBlock) * 100) / (epochSize * 100);

        for (uint256 i = 0; i < length; ++i) {
            // skip reward distribution for slashed validators
            if (slashingSet[i]) {
                continue;
            }
            UptimeData memory uptimeData = uptime.uptimeData[i];
            Validator storage validator = _validators.get(uptimeData.validator);
            // slither-disable-next-line divide-before-multiply
            uint256 validatorReward = (reward *
                (validator.stake + _validators.getDelegationPool(uptimeData.validator).supply) *
                uptimeData.signedBlocks) / (activeStake * uptime.totalBlocks);
            (uint256 validatorShares, uint256 delegatorShares) = _calculateValidatorAndDelegatorShares(
                uptimeData.validator,
                validatorReward
            );
            validator.withdrawableRewards += validatorShares;
            emit ValidatorRewardDistributed(uptimeData.validator, validatorReward);
            _validators.getDelegationPool(uptimeData.validator).distributeReward(delegatorShares);
            emit DelegatorRewardDistributed(uptimeData.validator, delegatorShares);
        }

        _processQueue();

        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    function _calculateValidatorAndDelegatorShares(address validatorAddr, uint256 totalReward)
        private
        view
        returns (uint256, uint256)
    {
        Validator memory validator = getValidator(validatorAddr);
        uint256 stakedAmount = validator.stake;
        uint256 delegations = _validators.getDelegationPool(validatorAddr).supply;

        if (stakedAmount == 0) return (0, 0);
        if (delegations == 0) return (totalReward, 0);

        uint256 validatorReward = (totalReward * stakedAmount) / (stakedAmount + delegations);
        uint256 delegatorReward = totalReward - validatorReward;

        uint256 commission = (validator.commission * delegatorReward) / 100;

        return (validatorReward + commission, delegatorReward - commission);
    }

    /**
     * @notice verifies an aggregated BLS signature using BLS precompile
     * @param hash hash of the message signed
     * @param signature the signed message
     * @param bitmap bitmap of which validators have signed
     */
    function _checkPubkeyAggregation(
        bytes32 hash,
        bytes calldata signature,
        bytes calldata bitmap
    ) private view {
        // verify signatures` for provided sig data and sigs bytes
        // slither-disable-next-line low-level-calls
        (bool callSuccess, bytes memory returnData) = VALIDATOR_PKCHECK_PRECOMPILE.staticcall{
            gas: VALIDATOR_PKCHECK_PRECOMPILE_GAS
        }(abi.encode(hash, signature, bitmap));
        bool verified = abi.decode(returnData, (bool));
        require(callSuccess && verified, "SIGNATURE_VERIFICATION_FAILED");
    }

    function _getValueFromBitmap(bytes calldata bitmap, uint256 index) private pure returns (bool) {
        uint256 byteNumber = index / 8;
        uint8 bitNumber = uint8(index % 8);

        if (byteNumber >= bitmap.length) {
            return false;
        }

        // Get the value of the bit at the given 'index' in a byte.
        return uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0;
    }

    function _assertUniqueBlockhash(DoubleSignerSlashingInput[] calldata inputs) private pure returns (bool) {
        uint256 length = inputs.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (inputs[i].blockHash == inputs[j].blockHash) {
                    return false;
                }
            }
        }
        return true;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
