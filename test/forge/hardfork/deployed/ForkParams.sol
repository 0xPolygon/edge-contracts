// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
