// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/**
 * @title StakeManagerStakingData
 * @notice Holds all staking related data.
 * Note that this is contract is designed to be included in StakeManager. It is upgradeable.
 */
abstract contract StakeManagerStakingData {
    uint256 internal theTotalStake;
    // validator => child => amount
    mapping(address => mapping(uint256 => uint256)) private stakes;
    // child chain id => total stake
    mapping(uint256 => uint256) private totalStakePerChild;
    // validator address => stake across all child chains.
    mapping(address => uint256) private totalStakes;
    // validator address => withdrawable stake.
    mapping(address => uint256) private withdrawableStakes;

    // Storage gap 
    // solhint-disable-next-line var-name-mixedcase
    uint256[1000] private __StorageGapStakeManagerStakingData;


    function _addStake(address validator, uint256 id, uint256 amount) internal {
        stakes[validator][id] += amount;
        totalStakePerChild[id] += amount;
        totalStakes[validator] += amount;
        theTotalStake += amount;
    }

    function _removeStake(address validator, uint256 id, uint256 amount) internal {
        stakes[validator][id] -= amount;
        totalStakePerChild[id] -= amount;
        totalStakes[validator] -= amount;
        theTotalStake -= amount;
        withdrawableStakes[validator] += amount;
    }

    function _withdrawStake(address validator, uint256 amount) internal {
        withdrawableStakes[validator] -= amount;
    }

    function _withdrawableStakeOf(address validator) internal view returns (uint256 amount) {
        amount = withdrawableStakes[validator];
    }

    function _totalStakeOfChild(uint256 id) internal view returns (uint256 amount) {
        amount = totalStakePerChild[id];
    }

    function _stakeOf(address validator, uint256 id) internal view returns (uint256 amount) {
        amount = stakes[validator][id];
    }

    function _totalStakeOf(address validator) internal view returns (uint256 amount) {
        amount = totalStakes[validator];
    }
}
