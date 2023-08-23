// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// the next import is to facilitate storage compatibility across versions of StakeManager
import {StakeManagerLegacyCompatStorage} from "./StakeManagerLegacyCompatStorage.sol";

/**
 * @title StakeManagerChildData
 * @notice Holds data to allow look-up between child chain manager contract address and child chain id.
 * Note that this is contract is designed to be included in StakeManager. It is upgradeable.
 */
abstract contract StakeManagerChildData is StakeManagerLegacyCompatStorage {
    /**
     * @notice Register a child chain manager contract and allocate a child chain id.
     * @param manager Child chain manager contract address.
     * @return id Child chain id allocated for the child chain.
     */
    function _registerChild(address manager) internal returns (uint256 id) {
        require(manager != address(0), "StakeManagerChildData: INVALID_ADDRESS");
        unchecked {
            id = ++counter;
        }
        __managers[id] = manager;
        _ids[manager] = id;
    }

    /**
     * @notice Get the child chain manager contract that corresponds to a child chain id.
     * @param id Child chain id.
     * @return manager Child chain manager contract address.
     */
    function _managerOf(uint256 id) internal view returns (address manager) {
        manager = __managers[id];
        require(manager != address(0), "StakeManagerChildData: INVALID_ID");
    }

    /**
     * @notice Get the child chain id that corresponds to a child chain manager contract.
     * @param manager Child chain manager contract address.
     * @return id Child chain id.
     */
    function _idFor(address manager) internal view returns (uint256 id) {
        id = _ids[manager];
        require(id != 0, "StakeManagerChildData: INVALID_MANAGER");
    }
}
