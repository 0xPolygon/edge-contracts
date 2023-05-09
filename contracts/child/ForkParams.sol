// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title ForkParams
    @author Polygon Technology (@QEDK)
    @notice Configurable softfork features that are read by the client on each epoch
    @dev The contract allows for configurable softfork parameters without genesis updation
 */
contract ForkParams is Ownable {
    mapping(bytes32 => uint256) public featureToBlockNumber; // keccak256("FEATURE_NAME") -> blockNumber

    event NewFeature(bytes32 indexed feature, uint256 indexed block);
    event UpdatedFeature(bytes32 indexed feature, uint256 indexed block);

    /**
     * @notice constructor function to set the owner
     * @param newOwner address to transfer the ownership to
     */
    constructor(address newOwner) {
        _transferOwnership(newOwner);
    }

    /**
     * @notice function to add a new feature at a block number
     * @dev block number must be set in the future and feature must already not be scheduled
     * @param blockNumber block number to schedule the feature
     * @param feature feature name to schedule
     */
    function addNewFeature(uint256 blockNumber, string calldata feature) external onlyOwner {
        require(blockNumber >= block.number, "ForkParams: INVALID_BLOCK");
        bytes32 featureHash = keccak256(abi.encode(feature));
        require(featureToBlockNumber[featureHash] == 0, "ForkParams: FEATURE_EXISTS");
        featureToBlockNumber[featureHash] = blockNumber;

        emit NewFeature(featureHash, blockNumber);
    }

    /**
     * @notice function to update the block number for a feature
     * @dev block number must be set in the future and feature must already be scheduled
     * @param newBlockNumber new block number to schedule the feature at
     * @param feature feature name to schedule
     */
    function updateFeatureBlock(uint256 newBlockNumber, string calldata feature) external onlyOwner {
        bytes32 featureHash = keccak256(abi.encode(feature));
        uint256 featureBlock = featureToBlockNumber[featureHash];
        require(featureBlock != 0, "ForkParams: NONEXISTENT_FEATURE");
        require(newBlockNumber >= block.number && block.number < featureBlock, "ForkParams: INVALID_BLOCK");
        featureToBlockNumber[featureHash] = newBlockNumber;

        emit UpdatedFeature(featureHash, newBlockNumber);
    }

    /**
     * @notice function to check if a feature is activated
     * @dev returns true if feature is activated, false if feature is scheduled in the future and reverts if feature does not exists
     * @param feature feature name to check for activation
     */
    function isFeatureActivated(string calldata feature) external view returns (bool) {
        uint256 featureBlock = featureToBlockNumber[keccak256(abi.encode(feature))];
        require(featureBlock != 0, "ForkParams: NONEXISTENT_FEATURE");
        if (block.number >= featureBlock) {
            return true;
        }
        return false;
    }
}
