// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./FlowRateDetection.sol";
import "./FlowRateWithdrawalQueue.sol";
import "../RootERC20Predicate.sol";

/**
 * @title  Root ERC 20 Predicate Flow Rate
 * @author Immutable Pty Ltd (Peter Robinson @drinkcoffee)
 * @notice Root chain contract for an ERC 20 Bridge, where the ERC 20 tokens have been minted on
 *         the root chain. Adds security features to help prevent or reduce the scope of attacks.
 * @dev    Features:
 *         - A withdrawal queue is defined. In certain situations, a crosschain transfer results
 *           in a withdrawal being put in a queue. Users can withdraw the amount after a delay.
 *           The default delay is one day.
 *         - Withdrawals of tokens whose amount is greater than a token specific threshold are
 *           put into the withdrawal queue.
 *         - If the rate of withdrawal of any token is over a token specific threshold, then all
 *           withdrwals are put into the withdrawal queue.
 *         - Withdrawals are put into the withdrawal queue when no thresholds have been defined
 *           for the token being withdrawn.
 *         - Role based access control is introduced.
 *         - All withdrawals can be paused by an account with the PAUSER role.
 *         - Administering the thresholds and withdrawal queue feature are controlled by an
 *           account with RATE role. This includes setting the thresholds for each token,
 *           manually enabling the queue for all tokens, and disabling the queue for all tokens.
 *
 *         Note that this is an upgradeable contract.
 */
contract RootERC20PredicateFlowRate is
    RootERC20Predicate,
    PausableUpgradeable,
    AccessControlUpgradeable,
    FlowRateDetection,
    FlowRateWithdrawalQueue
{
    using SafeERC20 for IERC20Metadata;

    // Constants used for access control
    bytes32 public constant PAUSER_ADMIN_ROLE = keccak256("PAUSER");
    bytes32 public constant UNPAUSER_ADMIN_ROLE = keccak256("UNPAUSER");
    bytes32 public constant RATE_CONTROL_ROLE = keccak256("RATE");

    // Threshold for large transfers
    // Map ERC 20 token address to threshold
    mapping(address => uint256) public largeTransferThresholds;

    error WrongInitializer();

    /**
     * @notice Indicates a withdrawal was queued.
     * @param token Address of token that is being withdrawn.
     * @param withdrawer Child chain sender of tokens.
     * @param receiver Recipient of tokens.
     * @param amount The number of tokens.
     * @param delayWithdrawalLargeAmount is true if the reason for queuing was a large transfer.
     * @param delayWithdrawalUnknownToken is true if the reason for queuing was that the
     *         token had not been configured using the setRateControlThreshold function.
     * @param withdrawalQueueActivated is true if the withdrawal queue has been activated.
     */
    event QueuedWithdrawal(
        address indexed token,
        address indexed withdrawer,
        address indexed receiver,
        uint256 amount,
        bool delayWithdrawalLargeAmount,
        bool delayWithdrawalUnknownToken,
        bool withdrawalQueueActivated
    );

    /**
     * Indicates that there were no queued withdrawals that were available to be
     * withdrawn.
     */
    event NoneAvailable();

    /**
     * @notice Initilization function for RootERC20PredicateFlowRate
     * @param superAdmin Address of administrator that defines other administrators.
     * @param pauseAdmin Address of administrator that controls pausing.
     * @param rateAdmin Address of administrator that controls thresholds and queues.
     * @param newStateSender Address of StateSender to send deposit information to
     * @param newExitHelper Address of ExitHelper to receive withdrawal information from
     * @param newChildERC20Predicate Address of child ERC20 predicate to communicate with.
     * @param newChildTokenTemplate Address of ERC 20 contract template that will be
     *           deployed on the child chain.
     * @param nativeTokenRootAddress Address of contract that wraps the root chain's native
     *           token on the root chain. That is, for Ethereum, this is the address of
     *           the wrapped Ether contract. If this is address 0, then don't set-up the
     *           bridge to use the native token.
     * @dev Can only be called once.
     */
    function initialize(
        address superAdmin,
        address pauseAdmin,
        address unpauseAdmin,
        address rateAdmin,
        address newStateSender,
        address newExitHelper,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        address nativeTokenRootAddress
    ) external initializer {
        __RootERC20Predicate_init(
            newStateSender,
            newExitHelper,
            newChildERC20Predicate,
            newChildTokenTemplate,
            nativeTokenRootAddress
        );
        __Pausable_init();
        __FlowRateWithdrawalQueue_init();

        _setupRole(DEFAULT_ADMIN_ROLE, superAdmin);
        _setupRole(PAUSER_ADMIN_ROLE, pauseAdmin);
        _setupRole(UNPAUSER_ADMIN_ROLE, unpauseAdmin);
        _setupRole(RATE_CONTROL_ROLE, rateAdmin);
    }

    // Ensure initialize from RootERC20Predicate can not be called.
    function initialize(address, address, address, address, address) external pure override {
        revert WrongInitializer();
    }

    /**
     * @notice Pause all withdrawals.
     * @dev Only PAUSER role.
     */
    function pause() external onlyRole(PAUSER_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause all withdrawals.
     * @dev Only PAUSER role.
     */
    function unpause() external onlyRole(UNPAUSER_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Activate the withdrawal queue for all tokens.
     * @dev This function manually activates the withdrawal queue. However the
     *      queue is automatically activated when the flow rate detection code
     *      determines that there is a large outflow of any token.
     *      Only RATE role.
     */
    function activateWithdrawalQueue() external onlyRole(RATE_CONTROL_ROLE) {
        _activateWithdrawalQueue();
    }

    /**
     * @notice Deactivate the withdrawal queue for all tokens.
     * @dev This function manually deactivates the withdrawal queue.
     *      Only RATE role.
     */
    function deactivateWithdrawalQueue() external onlyRole(RATE_CONTROL_ROLE) {
        _deactivateWithdrawalQueue();
    }

    /**
     * @notice Set the time in the queue for queued withdrawals.
     * @param delay The number of seconds between when the ExitHelper is called to
     *         complete a crosschain transfer and when finaliseHeldTransfers can be
     *         called.
     * @dev Only RATE role.
     */
    function setWithdrawalDelay(uint256 delay) external onlyRole(RATE_CONTROL_ROLE) {
        _setWithdrawalDelay(delay);
    }

    /**
     * @notice Set the thresholds to use for a certain token.
     * @param token The token to apply the thresholds to.
     * @param capacity The size of the bucket in tokens.
     * @param refillRate How quickly the bucket refills in tokens per second.
     * @param largeTransferThreshold Threshold over which a withdrawal is deemed to be large,
     *         and will be put in the withdrawal queue.
     * @dev Only RATE role.
     *
     * Example parameter values:
     *  Assume the desired configuration is:
     *  - large transfer threshold is 100,000 IMX.
     *  - high flow rate threshold is 1,000,000 IMX per hour.
     *  Further assume the ERC 20 contract has been configured with 18 decimals. This is true
     *  for IMX and MATIC.
     *
     *  The capacity should be set to the flow rate number. In this example, 1,000,000 IMX.
     *  The refill rate should be the capacity divided by the flow rate period in seconds.
     *   In this example, 1,000,000 IMX divided by 3600 seconds in an hour.
     *
     *  Hence, the configuration should be set to:
     *  - capacity = 1,000,000,000,000,000,000,000,000
     *  - refillRate =     277,777,777,777,777,777,777
     *  - largeTransferThreshold = 100,000,000,000,000,000,000,000
     */
    function setRateControlThreshold(
        address token,
        uint256 capacity,
        uint256 refillRate,
        uint256 largeTransferThreshold
    ) external onlyRole(RATE_CONTROL_ROLE) {
        _setFlowRateThreshold(token, capacity, refillRate);
        largeTransferThresholds[token] = largeTransferThreshold;
    }

    /**
     * @notice Complete crosschain transfer of funds.
     * @param data Contains the crosschain transfer information:
     *         - token: Token address on the root chain.
     *         - withdrawer: Account that initiated the transfer on the child chain.
     *         - receiver: Account to transfer tokens to.
     *         - amount: The number of tokens to transfer.
     * @dev Called by the ExitHelper.
     *      Only when not paused.
     */
    function _withdraw(bytes calldata data) internal override whenNotPaused {
        (
            address rootToken,
            address childToken,
            address withdrawer,
            address receiver,
            uint256 amount
        ) = _decodeCrosschainMessage(data);

        // Update the flow rate checking. Delay the withdrawal if the request was
        // for a token that has not been configured.
        bool delayWithdrawalUnknownToken = _updateFlowRateBucket(rootToken, amount);
        bool delayWithdrawalLargeAmount;

        // Delay the withdrawal if the amount is greater than the threshold.
        if (!delayWithdrawalUnknownToken) {
            delayWithdrawalLargeAmount = (amount >= largeTransferThresholds[rootToken]);
        }

        // Ensure storage variable is cached on the stack.
        bool queueActivated = withdrawalQueueActivated;

        if (delayWithdrawalLargeAmount || delayWithdrawalUnknownToken || queueActivated) {
            _enqueueWithdrawal(receiver, withdrawer, rootToken, amount);
            emit QueuedWithdrawal(
                rootToken,
                withdrawer,
                receiver,
                amount,
                delayWithdrawalLargeAmount,
                delayWithdrawalUnknownToken,
                queueActivated
            );
        } else {
            _executeTransfer(rootToken, childToken, withdrawer, receiver, amount);
        }
    }

    /**
     * @notice Withdraw a queued withdrawal.
     * @param receiver Address to withdraw value for.
     * @dev Only when not paused.
     */
    function finaliseQueuedWithdrawal(address receiver) external whenNotPaused {
        bool none = true;
        bool more;
        do {
            address withdrawer;
            address token;
            uint256 amount;
            (more, withdrawer, token, amount) = _dequeueWithdrawal(receiver);
            if (token == address(0)) {
                // No more help transfers to process.
                if (none) {
                    emit NoneAvailable();
                }
                return;
            }
            none = false;

            address childToken = rootTokenToChildToken[token];
            _executeTransfer(token, childToken, withdrawer, receiver, amount);
        } while (more);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
