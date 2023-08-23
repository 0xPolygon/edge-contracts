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
    @title NetworkParams
    @author Polygon Technology (@QEDK)
    @notice Configurable network parameters that are read by the client on each epoch
    @dev The contract allows for configurable network parameters without the need for a hardfork
 */
contract NetworkParams is Ownable {
    uint256 public blockGasLimit;
    uint256 public checkpointBlockInterval; // in blocks
    uint256 public minStake; // in wei
    uint256 public maxValidatorSetSize;

    event NewBlockGasLimit(uint256 indexed value);
    event NewCheckpointBlockInterval(uint256 indexed value);
    event NewMinStake(uint256 indexed value);
    event NewMaxValdidatorSetSize(uint256 indexed value);

    /**
     * @notice initializer for NetworkParams, sets the initial set of values for the network
     * @dev disallows setting of zero values for sanity check purposes
     * @param newOwner address of the contract controller to be set at deployment
     * @param newBlockGasLimit initial block gas limit
     * @param newCheckpointBlockInterval initial checkpoint interval
     * @param newMinStake initial minimum stake
     * @param newMaxValidatorSetSize initial max validator set size
     */
    constructor(
        address newOwner,
        uint256 newBlockGasLimit,
        uint256 newCheckpointBlockInterval,
        uint256 newMinStake,
        uint256 newMaxValidatorSetSize
    ) {
        require(
            newOwner != address(0) &&
                newBlockGasLimit != 0 &&
                newMinStake != 0 &&
                newCheckpointBlockInterval != 0 &&
                newMaxValidatorSetSize != 0,
            "NetworkParams: INVALID_INPUT"
        );
        blockGasLimit = newBlockGasLimit;
        checkpointBlockInterval = newCheckpointBlockInterval;
        minStake = newMinStake;
        maxValidatorSetSize = newMaxValidatorSetSize;
        _transferOwnership(newOwner);
    }

    /**
     * @notice function to set new block gas limit
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newBlockGasLimit new block gas limit
     */
    function setNewBlockGasLimit(uint256 newBlockGasLimit) external onlyOwner {
        require(newBlockGasLimit != 0, "NetworkParams: INVALID_BLOCK_GAS_LIMIT");
        blockGasLimit = newBlockGasLimit;

        emit NewBlockGasLimit(newBlockGasLimit);
    }

    /**
     * @notice function to set new checkpoint block interval
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newCheckpointBlockInterval new checkpoint block interval
     */
    function setNewCheckpointBlockInterval(uint256 newCheckpointBlockInterval) external onlyOwner {
        require(newCheckpointBlockInterval != 0, "NetworkParams: INVALID_CHECKPOINT_INTERVAL");
        checkpointBlockInterval = newCheckpointBlockInterval;

        emit NewCheckpointBlockInterval(newCheckpointBlockInterval);
    }

    /**
     * @notice function to set new minimum stake
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMinStake new minimum stake
     */
    function setNewMinStake(uint256 newMinStake) external onlyOwner {
        require(newMinStake != 0, "NetworkParams: INVALID_MIN_STAKE");
        minStake = newMinStake;

        emit NewMinStake(newMinStake);
    }

    /**
     * @notice function to set new maximum validator set size
     * @dev disallows setting of a zero value for sanity check purposes
     * @param newMaxValidatorSetSize new maximum validator set size
     */
    function setNewMaxValidatorSetSize(uint256 newMaxValidatorSetSize) external onlyOwner {
        require(newMaxValidatorSetSize != 0, "NetworkParams: INVALID_MAX_VALIDATOR_SET_SIZE");
        maxValidatorSetSize = newMaxValidatorSetSize;

        emit NewMaxValdidatorSetSize(newMaxValidatorSetSize);
    }
}
