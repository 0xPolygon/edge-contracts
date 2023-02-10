// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IStateSender.sol";

// solhint-disable reason-string
contract RootERC20Predicate is Initializable {
    using SafeERC20 for IERC20Metadata;

    struct ERC20BridgeEvent {
        address rootToken;
        address childToken;
        address sender;
        address receiver;
    }

    IStateSender public stateSender;
    address public exitHelper;
    address public childERC20Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;

    event ERC20Deposit(
        address indexed rootToken,
        address indexed childToken,
        address depositor,
        address indexed receiver,
        uint256 amount
    );
    event ERC20Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address withdrawer,
        address indexed receiver,
        uint256 amount
    );
    event TokenMapped(address indexed rootToken, address indexed childToken);

    /**
     * @notice Initilization function for RootERC20Predicate
     * @param newStateSender Address of StateSender to send deposit information to
     * @param newExitHelper Address of ExitHelper to receive withdrawal information from
     * @param newChildERC20Predicate Address of child ERC20 predicate to communicate with
     * @dev Can only be called once.
     */
    function initialize(
        address newStateSender,
        address newExitHelper,
        address newChildERC20Predicate,
        address newChildTokenTemplate
    ) external initializer {
        require(
            newStateSender != address(0) &&
                newExitHelper != address(0) &&
                newChildERC20Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "RootERC20Predicate: BAD_INITIALIZATION"
        );
        stateSender = IStateSender(newStateSender);
        exitHelper = newExitHelper;
        childERC20Predicate = newChildERC20Predicate;
        childTokenTemplate = newChildTokenTemplate;
    }

    /**
     * @notice Function to be used for token withdrawals
     * @param sender Address of the sender on the child chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "RootERC20Predicate: ONLY_EXIT_HELPER");
        require(sender == childERC20Predicate, "RootERC20Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _withdraw(data[32:]);
        } else {
            revert("RootERC20Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Function to deposit tokens from the depositor to themselves on the child chain
     * @param rootToken Address of the root token being deposited
     * @param amount Amount to deposit
     */
    function deposit(IERC20Metadata rootToken, uint256 amount) external {
        _deposit(rootToken, msg.sender, amount);
    }

    /**
     * @notice Function to deposit tokens from the depositor to another address on the child chain
     * @param rootToken Address of the root token being deposited
     * @param amount Amount to deposit
     */
    function depositTo(IERC20Metadata rootToken, address receiver, uint256 amount) external {
        _deposit(rootToken, receiver, amount);
    }

    /**
     * @notice Function to be used for token mapping
     * @param rootToken Address of the root token to map
     * @dev Called internally on deposit if token is not mapped already
     */
    function mapToken(IERC20Metadata rootToken) public {
        require(address(rootToken) != address(0), "RootERC20Predicate: INVALID_TOKEN");
        require(rootTokenToChildToken[address(rootToken)] == address(0), "RootERC20Predicate: ALREADY_MAPPED");

        address childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childERC20Predicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        stateSender.syncState(
            childERC20Predicate,
            abi.encode(MAP_TOKEN_SIG, rootToken, rootToken.name(), rootToken.symbol(), rootToken.decimals())
        );
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);
    }

    function _deposit(IERC20Metadata rootToken, address receiver, uint256 amount) private {
        if (rootTokenToChildToken[address(rootToken)] == address(0)) {
            mapToken(rootToken);
        }

        address childToken = rootTokenToChildToken[address(rootToken)];

        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist

        rootToken.safeTransferFrom(msg.sender, address(this), amount);

        stateSender.syncState(childERC20Predicate, abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, amount));
        // slither-disable-next-line reentrancy-events
        emit ERC20Deposit(address(rootToken), childToken, msg.sender, receiver, amount);
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
        emit ERC20Withdraw(address(rootToken), childToken, withdrawer, receiver, amount);
    }
}
