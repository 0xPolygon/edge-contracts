// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./modules/ICVSStorage.sol";

/**
 * @title ChildValidatorSet
 * @author Polygon Technology
 * @notice Validator set genesis contract for Polygon PoS v3. This contract serves the purpose of storing stakes.
 * @dev The contract is used to complete validator registration and store self-stake and delegated MATIC amounts.
 * It manages staking, epoch committing, and reward distribution.
 */
interface IChildValidatorSetBase {
    struct InitStruct {
        uint256 epochReward;
        uint256 minStake;
        uint256 minDelegation;
        uint256 epochSize;
    }

    struct ValidatorInit {
        address addr;
        uint256[4] pubkey;
        uint256[2] signature;
        uint256 stake;
    }

    struct DoubleSignerSlashingInput {
        uint256 epochId;
        bytes32 eventRoot;
        bytes32 currentValidatorSetHash;
        bytes32 nextValidatorSetHash;
        bytes32 blockHash;
        bytes bitmap;
        bytes signature;
    }

    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);
    event DoubleSignerSlashed(address indexed key, uint256 indexed epoch, uint256 indexed pbftRound);

    /**
     * @notice Allows the v3 client to commit epochs to this contract.
     * @param id ID of epoch to be committed
     * @param epoch Epoch data to be committed
     * @param uptime Uptime data for the epoch being committed
     */
    function commitEpoch(uint256 id, Epoch calldata epoch, Uptime calldata uptime) external;

    /**
     * @notice Allows the v3 client to commit epoch and slash double signers.
     * @param curEpochId ID of epoch to be committed
     * @param epoch Epoch data to be committed
     * @param uptime Uptime data for the epoch being committed
     * @param blockNumber Block number at which double signer occurred
     * @param pbftRound Round number at which double signing occurred
     * @param inputs Information about double signers to be slashed along with signatures and bitmap
     */
    function commitEpochWithDoubleSignerSlashing(
        uint256 curEpochId,
        uint256 blockNumber,
        uint256 pbftRound,
        Epoch calldata epoch,
        Uptime calldata uptime,
        DoubleSignerSlashingInput[] calldata inputs
    ) external;

    /**
     * @notice Gets addresses of active validators in this epoch, sorted by total stake (self-stake + delegation)
     * @return Array of addresses of active validators in this epoch, sorted by total stake
     */
    function getCurrentValidatorSet() external view returns (address[] memory);

    /**
     * @notice Look up an epoch by block number. Searches in O(log n) time.
     * @param blockNumber ID of epoch to be committed
     * @return Epoch Returns epoch if found, or else, the last epoch
     */
    function getEpochByBlock(uint256 blockNumber) external view returns (Epoch memory);

    /**
     * @notice Calculates total stake of active validators (self-stake + delegation).
     * @return Total stake of active validators (in MATIC wei)
     */
    function totalActiveStake() external view returns (uint256);
}
