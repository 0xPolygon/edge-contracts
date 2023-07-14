// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RootERC20Predicate.sol";

/**
 * Root change end point for ERC 20 transfers, adding flow control capability.
 *
 * Features:
 * * withdraw can be paused.
 * * large transfers can be put in a queue
 * * rate control
 */
// solhint-disable reason-string
contract RootERC20PredicateFlowControl is RootERC20Predicate, PausableUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant PAUSER_ADMIN_ROLE = keccak256("PAUSER");
    bytes32 public constant RATE_CONTROL_ROLE = keccak256("RATE");
    bool isBridgeRateLimited = false;

    Event LargeTransferHeld(address token, address receiver, uint256 amount)

    struct Bucket {
        uint256 remainingTokens;
        uint256 lastRefillTime;
        uint256 maxTokenCapacity;
        uint256 refillRate;
        uint256 refillSize;
    }

    struct PendingLargeWithdrawal {
        address token;
        uint256 withdrawalAmount;
        uint256 withdrawalTimestamp;
        address receiver;
    }

    // Threshold for large transfers
    // Map ERC 20 token address to threshold
    mapping(address => uint256) public largeTransferThresholds;

    // Threshold for large flow rate
    // Map ERC 20 token address to threshold
    mapping(address => Bucket) public flowRateThresholds;

    mapping(address => PendingLargeWithdrawal) public pendingLargeWithdrawals;

    /**
     * @notice Initilization function for RootERC20Predicate
       // TODO doc
     * @param newStateSender Address of StateSender to send deposit information to
     * @param newExitHelper Address of ExitHelper to receive withdrawal information from
     * @param newChildERC20Predicate Address of child ERC20 predicate to communicate with
     * @dev Can only be called once.
     */
    function initialize(
        address superAdmin,
        address pauseAdmin,
        address rateAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        address nativeTokenRootAddress
    ) external {
        super.initialize(
            newStateSender,
            newExitHelper,
            newChildERC20Predicate,
            newChildTokenTemplate,
            nativeTokenRootAddress
        );
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, superAdmin);
        _setupRole(PAUSER_ADMIN_ROLE, pauseAdmin);
        _setupRole(RATE_CONTROL_ROLE, rateAdmin);
    }

    // TODO doc
    function pause() external onlyRole(PAUSER_ADMIN_ROLE) {
        _pause();
    }

    // TODO doc
    function unpause() external onlyRole(PAUSER_ADMIN_ROLE) {
        _unpause();
    }

    function unrateLimit() external onlyRole(RATE_CONTROL_ROLE) {
        isBridgeRateLimited = false;
    }

    // TODO doc
    function setRateControlThreshold(
        address token,
        uint256 maxCapacity,
        uint256 refillRate,
        uint256 maxTransferLimit,
        uint256 refillSize
    ) external onlyRole(RATE_CONTROL_ROLE) {
        Bucket storage bucket = flowRateThresholds[token];
        bucket.maxTokenCapacity = maxCapacity;
        bucket.refillRate = refillRate;
        bucket.refillSize = refillSize;
        largeTransferThresholds[token] = maxTransferLimit;
    }

    function _withdraw(bytes calldata data) internal override whenNotPaused {
        (address rootToken, address withdrawer, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        // TODO call to function to check for large transfer or flow rate
        if amount >= largeTransferThresholds[rootToken] {
            isBridgeRateLimited = true;
        }

        bucket = flowRateThresholds[rootToken];

        assert(bucket.maxCapacity != 0)

        if bucket.lastRefillTime == 0 {
            bucket.lastRefillTime = block.timestamp;
            bucket.remainingTokens = bucket.maxTokenCapacity;
        } else {
            bucket.remainingTokens = (block.timestamp - bucket.lastRefillTime) * bucket.refillSize / bucket.refillRate;
            if bucket.remainingTokens > bucket.maxTokenCapacity {
                bucket.remainingTokens = bucket.maxTokenCapacity;
            }
        }

        if amount > bucket.remainingTokens {
            isBridgeRateLimited = true;
            bucket.remainingTokens = 0;
        } else {
            bucket.remainingTokens -= amount;
        }

        if isBridgeRateLimited {
            PendingLargeWithdrawal storage withdrawal = pendingLargeWithdrawals[receiver];
            if withdrawal.withdrawalTimestamp != 0 {
                revert("Large transfer already pending");
            }
            withdrawal.token = rootToken;
            withdrawal.withdrawalAmount = amount;
            withdrawal.withdrawalTimestamp = block.timestamp;
            withdrawal.receiver = receiver;
            emit LargeTransferHeld(rootToken, receiver, amount);
        } else {
            IERC20Metadata(rootToken).safeTransfer(receiver, amount);
            emit ERC20Withdraw(address(rootToken), childToken, withdrawer, receiver, amount);
        }
        
    }

    function finaliseHeldTransfers(address receiver) external {
        pendingTransfer = pendingLargeWithdrawals[receiver];
        if pendingTransfer.withdrawalTimestamp == 0 {
            revert("No pending transfer");
        }
        if (block.timestamp - pendingTransfer.withdrawalTimestamp) < 86400 {
            revert("Transfer not held for long enough");
        }
        IERC20Metadata(rootToken).safeTransfer(pendingTransfer.receiver, pendingTransfer.amount);
        pendingTransfer.withdrawalTimestamp = 0;
        address childToken = rootTokenToChildToken[pendingTransfer.token];
        emit ERC20Withdraw(address(pendingTransfer.token), childToken, msg.sender, pendingTransfer.receiver, pendingTransfer.amount);
    }

    // TODO for rate control, optionally allow for automatic pause

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
