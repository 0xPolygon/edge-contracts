// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StakeManagerLegacyCompatStorage} from "./StakeManagerLegacyCompatStorage.sol";

/**
 * @title StakeManagerStakingData
 * @notice Holds all staking related data.
 * Note that this is contract is designed to be included in StakeManager. It is upgradeable.
 */
abstract contract StakeManagerStakingData is StakeManagerLegacyCompatStorage {
    function _addStake(address validator, uint256 id, uint256 amount) internal {
        __stakes[validator][id] += amount;
        __totalStakePerChild[id] += amount;
        __totalStakes[validator] += amount;
        _totalStake += amount;
    }

    function _removeStake(address validator, uint256 id, uint256 amount) internal {
        __stakes[validator][id] -= amount;
        __totalStakePerChild[id] -= amount;
        __totalStakes[validator] -= amount;
        _totalStake -= amount;
        __withdrawableStakes[validator] += amount;
    }

    function _withdrawStake(address validator, uint256 amount) internal {
        __withdrawableStakes[validator] -= amount;
    }

    function _withdrawableStakeOf(address validator) internal view returns (uint256 amount) {
        amount = __withdrawableStakes[validator];
    }

    function _totalStakeOfChild(uint256 id) internal view returns (uint256 amount) {
        amount = __totalStakePerChild[id];
    }

    function _stakeOf(address validator, uint256 id) internal view returns (uint256 amount) {
        amount = __stakes[validator][id];
    }

    function _totalStakeOf(address validator) internal view returns (uint256 amount) {
        amount = __totalStakes[validator];
    }
}
