// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/child/IRootMintableERC20Predicate.sol";
import "../interfaces/IStateSender.sol";
import "./System.sol";

// solhint-disable reason-string
contract RootMintableERC20Predicate is IRootMintableERC20Predicate, Initializable, System {
    using SafeERC20 for IERC20Metadata;

    /// @custom:security write-protection="onlySystemCall()"
    IStateSender public l2StateSender;
    /// @custom:security write-protection="onlySystemCall()"
    address public stateReceiver;
    /// @custom:security write-protection="onlySystemCall()"
    address public childERC20Predicate;
    /// @custom:security write-protection="onlySystemCall()"
    address public childTokenTemplate;

    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;

    /**
     * @notice Initilization function for RootMintableERC20Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newChildERC20Predicate Address of child ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can only be called once.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate
    ) public virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newChildERC20Predicate, newChildTokenTemplate);
    }

    /**
     * @notice Function to be used for token withdrawals
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == stateReceiver, "RootMintableERC20Predicate: ONLY_STATE_RECEIVER");
        require(sender == childERC20Predicate, "RootMintableERC20Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _beforeTokenWithdraw();
            _withdraw(data[32:]);
            _afterTokenWithdraw();
        } else {
            revert("RootMintableERC20Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootMintableERC20Predicate
     */
    function deposit(IERC20Metadata rootToken, uint256 amount) external {
        _deposit(rootToken, msg.sender, amount);
    }

    /**
     * @inheritdoc IRootMintableERC20Predicate
     */
    function depositTo(IERC20Metadata rootToken, address receiver, uint256 amount) external {
        _deposit(rootToken, receiver, amount);
    }

    /**
     * @inheritdoc IRootMintableERC20Predicate
     */
    function mapToken(IERC20Metadata rootToken) public returns (address) {
        require(address(rootToken) != address(0), "RootMintableERC20Predicate: INVALID_TOKEN");
        require(rootTokenToChildToken[address(rootToken)] == address(0), "RootMintableERC20Predicate: ALREADY_MAPPED");

        address childPredicate = childERC20Predicate;

        address childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        l2StateSender.syncState(
            childPredicate,
            abi.encode(MAP_TOKEN_SIG, rootToken, rootToken.name(), rootToken.symbol(), rootToken.decimals())
        );
        // slither-disable-next-line reentrancy-events
        emit L2MintableTokenMapped(address(rootToken), childToken);

        return childToken;
    }

    /**
     * @notice Internal initialization function for RootMintableERC20Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newChildERC20Predicate Address of root ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC20Predicate,
        address newChildTokenTemplate
    ) internal {
        require(
            newL2StateSender != address(0) &&
                newStateReceiver != address(0) &&
                newChildERC20Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "RootMintableERC20Predicate: BAD_INITIALIZATION"
        );
        l2StateSender = IStateSender(newL2StateSender);
        stateReceiver = newStateReceiver;
        childERC20Predicate = newChildERC20Predicate;
        childTokenTemplate = newChildTokenTemplate;
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    function _deposit(IERC20Metadata rootToken, address receiver, uint256 amount) private {
        _beforeTokenDeposit();
        address childToken = rootTokenToChildToken[address(rootToken)];

        if (childToken == address(0)) {
            childToken = mapToken(rootToken);
        }

        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist

        rootToken.safeTransferFrom(msg.sender, address(this), amount);

        l2StateSender.syncState(childERC20Predicate, abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, amount));
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC20Deposit(address(rootToken), childToken, msg.sender, receiver, amount);
        _afterTokenDeposit();
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC20Metadata(rootToken).safeTransfer(receiver, amount);
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC20Withdraw(address(rootToken), childToken, withdrawer, receiver, amount);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
