// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title StakeManagerChildData
 * @notice Holds data to allow look-up between child chain manager contract address and child chain id.
 * Note that this is contract is designed to be included in StakeManager. It is upgradeable.
 */
abstract contract StakeManagerChildData {
    // Highest child chain id allocated thus far. Child chain id 0x00 is an invalid id.
    uint256 internal counter;
    // child chain id to child chain manager contract address.
    mapping(uint256 => address) private managers;
    // child chain manager contract address to child chain id.
    mapping(address => uint256) private ids;

    /**
     * @notice Register a child chain manager contract and allocate a child chain id.
     * @param manager Child chain manager contract address.
     * @return id Child chain id allocated for the child chain.
     */
    function _registerChild(address manager) internal returns (uint256 id) {
        assert(manager != address(0));
        unchecked {
            id = ++counter;
        }
        managers[id] = manager;
        ids[manager] = id;
    }

    /** 
     * @notice Get the child chain manager contract that corresponds to a child chain id.
     * @param id Child chain id.
     * @return manager Child chain manager contract address.
     */
    function _managerOf(uint256 id) internal view returns (address manager) {
        manager = managers[id];
        require(manager != address(0), "Invalid id");
    }

    /** 
     * @notice Get the child chain id that corresponds to a child chain manager contract.
     * @param manager Child chain manager contract address.
     * @return id Child chain id.
     */
    function _idFor(address manager) internal view returns (uint256 id) {
        id = ids[manager];
        require(id != 0, "Invalid manager");
    }

    // Storage gap 
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StorageGapStakeManagerChildData;
}
