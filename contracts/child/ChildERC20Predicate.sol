// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IStateSender.sol";
import "../interfaces/IChildERC20.sol";
import "../interfaces/IStateReceiver.sol";
import "./System.sol";

/**
    @title ChildERC20Predicate
    @author Polygon Technology (@QEDK)
    @notice Enables ERC20 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC20Predicate is Initializable, System, IStateReceiver {
    using SafeERC20 for IERC20;

    struct ERC20BridgeEvent {
        address rootToken;
        address childToken;
        address sender;
        address receiver;
    }

    /// @custom:security write-protection="onlySystemCall()"
    IStateSender public l2StateSender;
    /// @custom:security write-protection="onlySystemCall()"
    address public stateReceiver;
    /// @custom:security write-protection="onlySystemCall()"
    address public rootERC20Predicate;
    /// @custom:security write-protection="onlySystemCall()"
    address public childTokenTemplate;
    /// @custom:security write-protection="onlySystemCall()"
    address public nativeTokenRootAddress;
    address public constant NATIVE_TOKEN_CHILD_ADDRESS = 0x0000000000000000000000000000000000001010;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");

    mapping(address => address) public childTokenToRootToken;

    event L2ERC20Deposit(ERC20BridgeEvent indexed deposit, uint256 amount);
    event L2ERC20Withdraw(ERC20BridgeEvent indexed withdrawal, uint256 amount);

    /**
     * @notice Initilization function for ChildERC20Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newRootERC20Predicate Address of root ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @param newNativeTokenRootAddress Address of native token on root chain
     * @param newNativeTokenName Name of native token ERC20
     * @param newNativeTokenSymbol Symbol of native token ERC20
     * @dev Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress,
        string calldata newNativeTokenName,
        string calldata newNativeTokenSymbol,
        uint8 newNativeTokenDecimals
    ) external onlySystemCall initializer {
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
        IChildERC20(NATIVE_TOKEN_CHILD_ADDRESS).initialize(
            newNativeTokenRootAddress,
            newNativeTokenName,
            newNativeTokenSymbol,
            newNativeTokenDecimals
        ); // native token root address must be initialized as zero address where no root token exists
    }

    /**
     * @notice Function to be used for mapping a root token to a child token
     * @param rootToken Address of the root token being mapped
     * @param salt Salt to use for CREATE2 deploymentAdd
     * @param name Name of the child token
     * @param symbol Symbol of the child token
     * @param decimals Decimals of the child token (should match root token)
     * @dev Allows for arbitrary N-to-M mappings for any root token to a child token
     */
    function deployChildToken(
        address rootToken,
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external {
        IChildERC20 childToken = IChildERC20(Clones.cloneDeterministic(childTokenTemplate, salt));
        childToken.initialize(rootToken, name, symbol, decimals);
        // slither-disable-next-line reentrancy-benign
        childTokenToRootToken[address(childToken)] = rootToken;
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
        (
            bytes32 signature,
            address rootToken,
            address childToken,
            address depositor,
            address receiver,
            uint256 amount
        ) = abi.decode(data, (bytes32, address, address, address, address, uint256));

        if (signature == WITHDRAW_SIG) {
            _deposit(rootToken, IChildERC20(childToken), depositor, receiver, amount);
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
        _withdraw(childToken, msg.sender, amount);
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to another address on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receiver Address of the receiver on the root chain
     * @param amount Amount to withdraw
     */
    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external {
        _withdraw(childToken, receiver, amount);
    }

    function _withdraw(IChildERC20 childToken, address receiver, uint256 amount) private {
        require(address(childToken).code.length != 0, "ChildERC20Predicate: NOT_CONTRACT");

        address rootToken = childToken.rootToken();

        require(childTokenToRootToken[address(childToken)] == rootToken, "ChildERC20Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));
        require(childToken.burn(msg.sender, amount), "ChildERC20Predicate: BURN_FAILED");
        l2StateSender.syncState(
            rootERC20Predicate,
            abi.encode(WITHDRAW_SIG, rootToken, childToken, msg.sender, receiver, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit L2ERC20Withdraw(ERC20BridgeEvent(rootToken, address(childToken), msg.sender, receiver), amount);
    }

    function _deposit(
        address depositToken,
        IChildERC20 childToken,
        address depositor,
        address receiver,
        uint256 amount
    ) private {
        require(address(childToken).code.length != 0, "ChildERC20Predicate: NOT_CONTRACT");

        address rootToken = childToken.rootToken();

        // deposited root token for child token is incorrect
        require(rootToken == depositToken, "ChildERC20Predicate: WRONG_DEPOSIT_TOKEN");
        require(childTokenToRootToken[address(childToken)] == rootToken, "ChildERC20Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));
        require(childToken.mint(receiver, amount), "ChildERC20Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit L2ERC20Deposit(ERC20BridgeEvent(depositToken, address(childToken), depositor, receiver), amount);
    }
}
