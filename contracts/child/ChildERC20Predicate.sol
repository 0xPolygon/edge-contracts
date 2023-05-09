// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/child/IChildERC20Predicate.sol";
import "../interfaces/child/IChildERC20.sol";
import "../interfaces/IStateSender.sol";
import "./System.sol";

/**
    @title ChildERC20Predicate
    @author Polygon Technology (@QEDK)
    @notice Enables ERC20 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC20Predicate is IChildERC20Predicate, Initializable, System {
    using SafeERC20 for IERC20;

    /// @custom:security write-protection="onlySystemCall()"
    IStateSender public l2StateSender;
    /// @custom:security write-protection="onlySystemCall()"
    address public stateReceiver;
    /// @custom:security write-protection="onlySystemCall()"
    address public rootERC20Predicate;
    /// @custom:security write-protection="onlySystemCall()"
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    mapping(address => address) public rootTokenToChildToken;

    event L2ERC20Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 amount
    );
    event L2ERC20Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 amount
    );
    event L2TokenMapped(address indexed rootToken, address indexed childToken);

    /**
     * @notice Initilization function for ChildERC20Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newRootERC20Predicate Address of root ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @param newNativeTokenRootAddress Address of native token on root chain
     * @dev Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress
    ) public virtual onlySystemCall initializer {
        _initialize(
            newL2StateSender,
            newStateReceiver,
            newRootERC20Predicate,
            newChildTokenTemplate,
            newNativeTokenRootAddress
        );
    }

    /**
     * @notice Function to be used for token deposits
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == stateReceiver, "ChildERC20Predicate: ONLY_STATE_RECEIVER");
        require(sender == rootERC20Predicate, "ChildERC20Predicate: ONLY_ROOT_PREDICATE");

        if (bytes32(data[:32]) == DEPOSIT_SIG) {
            _beforeTokenDeposit();
            _deposit(data[32:]);
            _afterTokenDeposit();
        } else if (bytes32(data[:32]) == MAP_TOKEN_SIG) {
            _mapToken(data);
        } else {
            revert("ChildERC20Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to themselves on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param amount Amount to withdraw
     */
    function withdraw(IChildERC20 childToken, uint256 amount) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, msg.sender, amount);
        _afterTokenWithdraw();
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to another address on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receiver Address of the receiver on the root chain
     * @param amount Amount to withdraw
     */
    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, receiver, amount);
        _afterTokenWithdraw();
    }

    /**
     * @notice Internal initialization function for ChildERC20Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newRootERC20Predicate Address of root ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @param newNativeTokenRootAddress Address of native token on root chain
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress
    ) internal {
        require(
            newL2StateSender != address(0) &&
                newStateReceiver != address(0) &&
                newRootERC20Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "ChildERC20Predicate: BAD_INITIALIZATION"
        );
        l2StateSender = IStateSender(newL2StateSender);
        stateReceiver = newStateReceiver;
        rootERC20Predicate = newRootERC20Predicate;
        childTokenTemplate = newChildTokenTemplate;
        if (newNativeTokenRootAddress != address(0)) {
            rootTokenToChildToken[newNativeTokenRootAddress] = NATIVE_TOKEN_CONTRACT;
            // slither-disable-next-line reentrancy-events
            emit L2TokenMapped(newNativeTokenRootAddress, NATIVE_TOKEN_CONTRACT);
        }
    }

    // solhint-disable no-empty-blocks
    function _beforeTokenDeposit() internal virtual {}

    // slither-disable-next-line dead-code
    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    function _withdraw(IChildERC20 childToken, address receiver, uint256 amount) private {
        require(address(childToken).code.length != 0, "ChildERC20Predicate: NOT_CONTRACT");

        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildERC20Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(childToken.burn(msg.sender, amount), "ChildERC20Predicate: BURN_FAILED");
        l2StateSender.syncState(rootERC20Predicate, abi.encode(WITHDRAW_SIG, rootToken, msg.sender, receiver, amount));

        // slither-disable-next-line reentrancy-events
        emit L2ERC20Withdraw(rootToken, address(childToken), msg.sender, receiver, amount);
    }

    function _deposit(bytes calldata data) private {
        (address depositToken, address depositor, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );

        IChildERC20 childToken = IChildERC20(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildERC20Predicate: UNMAPPED_TOKEN");
        assert(address(childToken).code.length != 0);

        address rootToken = IChildERC20(childToken).rootToken();

        // a mapped child token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC20(childToken).predicate() == address(this));

        require(IChildERC20(childToken).mint(receiver, amount), "ChildERC20Predicate: MINT_FAILED");

        // slither-disable-next-line reentrancy-events
        emit L2ERC20Deposit(depositToken, address(childToken), depositor, receiver, amount);
    }

    /**
     * @notice Function to be used for mapping a root token to a child token
     * @dev Allows for 1-to-1 mappings for any root token to a child token
     */
    function _mapToken(bytes calldata data) private {
        (, address rootToken, string memory name, string memory symbol, uint8 decimals) = abi.decode(
            data,
            (bytes32, address, string, string, uint8)
        );
        assert(rootToken != address(0)); // invariant since root predicate performs the same check
        assert(rootTokenToChildToken[rootToken] == address(0)); // invariant since root predicate performs the same check
        IChildERC20 childToken = IChildERC20(
            Clones.cloneDeterministic(childTokenTemplate, keccak256(abi.encodePacked(rootToken)))
        );
        rootTokenToChildToken[rootToken] = address(childToken);
        childToken.initialize(rootToken, name, symbol, decimals);

        // slither-disable-next-line reentrancy-events
        emit L2TokenMapped(rootToken, address(childToken));
    }
}
