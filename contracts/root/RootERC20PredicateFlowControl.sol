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

    // Threshold for large transfers
    // Map ERC 20 token address to threshold
    mapping(address => uint256) public largeTransferThresholds;

    // Threshold for large flow rate
    // Map ERC 20 token address to threshold
    mapping(address => uint256) public flowRateThresholds;

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

    // TODO doc
    function setRateControlThreshold(
        address token,
        uint256 largeTransfer,
        uint256 flowRate
    ) external onlyRole(RATE_CONTROL_ROLE) {
        largeTransferThresholds[token] = largeTransfer;
        flowRateThresholds[token] = flowRate;
    }

    function _withdraw(bytes calldata data) internal override whenNotPaused {
        (address rootToken, address withdrawer, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        // TODO call to function to check for large transfer or flow rate
        // TODO if a transfer is being held, then return and emit an event

        IERC20Metadata(rootToken).safeTransfer(receiver, amount);
        // slither-disable-next-line reentrancy-events
        emit ERC20Withdraw(address(rootToken), childToken, withdrawer, receiver, amount);
    }

    // TODO for rate control, optionally allow for automatic pause

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
