// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IStateSender.sol";

// solhint-disable reason-string
contract RootERC1155Predicate is Initializable {
    struct ERC1155BridgeEvent {
        address rootToken;
        address childToken;
        address sender;
        address receiver;
    }

    IStateSender public stateSender;
    address public exitHelper;
    address public childERC1155Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;

    event ERC1155Deposit(
        address indexed rootToken,
        address indexed childToken,
        address depositor,
        address indexed receiver,
        uint256 id,
        uint256 amount
    );
    event ERC1155Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address withdrawer,
        address indexed receiver,
        uint256 id,
        uint256 amount
    );
    event TokenMapped(address indexed rootToken, address indexed childToken);

    /**
     * @notice Initilization function for RootERC1155Predicate
     * @param newStateSender Address of StateSender to send deposit information to
     * @param newExitHelper Address of ExitHelper to receive withdrawal information from
     * @param newChildERC1155Predicate Address of child ERC1155 predicate to communicate with
     * @dev Can only be called once.
     */
    function initialize(
        address newStateSender,
        address newExitHelper,
        address newChildERC1155Predicate,
        address newChildTokenTemplate,
        address nativeTokenRootAddress
    ) external initializer {
        require(
            newStateSender != address(0) &&
                newExitHelper != address(0) &&
                newChildERC1155Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "RootERC1155Predicate: BAD_INITIALIZATION"
        );
        stateSender = IStateSender(newStateSender);
        exitHelper = newExitHelper;
        childERC1155Predicate = newChildERC1155Predicate;
        childTokenTemplate = newChildTokenTemplate;
        if (nativeTokenRootAddress != address(0)) {
            rootTokenToChildToken[nativeTokenRootAddress] = 0x0000000000000000000000000000000000001010;
            emit TokenMapped(nativeTokenRootAddress, 0x0000000000000000000000000000000000001010);
        }
    }

    /**
     * @notice Function to be used for token withdrawals
     * @param sender Address of the sender on the child chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "RootERC1155Predicate: ONLY_EXIT_HELPER");
        require(sender == childERC1155Predicate, "RootERC1155Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _withdraw(data[32:]);
        } else {
            revert("RootERC1155Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Function to deposit tokens from the depositor to themselves on the child chain
     * @param rootToken Address of the root token being deposited
     * @param id Index of the NFT to deposit
     * @param amount Amount to deposit
     */
    function deposit(IERC1155MetadataURI rootToken, uint256 id, uint256 amount) external {
        _deposit(rootToken, msg.sender, id, amount);
    }

    /**
     * @notice Function to deposit tokens from the depositor to another address on the child chain
     * @param rootToken Address of the root token being deposited
     * @param id Index of the NFT to deposit
     * @param amount Amount to deposit
     */
    function depositTo(IERC1155MetadataURI rootToken, address receiver, uint256 id, uint256 amount) external {
        _deposit(rootToken, receiver, id, amount);
    }

    /**
     * @notice Function to be used for token mapping
     * @param rootToken Address of the root token to map
     * @dev Called internally on deposit if token is not mapped already
     */
    function mapToken(IERC1155MetadataURI rootToken) public {
        require(address(rootToken) != address(0), "RootERC1155Predicate: INVALID_TOKEN");
        require(rootTokenToChildToken[address(rootToken)] == address(0), "RootERC1155Predicate: ALREADY_MAPPED");

        address childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childERC1155Predicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        stateSender.syncState(childERC1155Predicate, abi.encode(MAP_TOKEN_SIG, rootToken));
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);
    }

    function _deposit(IERC1155MetadataURI rootToken, address receiver, uint256 id, uint256 amount) private {
        if (rootTokenToChildToken[address(rootToken)] == address(0)) {
            mapToken(rootToken);
        }

        address childToken = rootTokenToChildToken[address(rootToken)];

        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist

        rootToken.safeTransferFrom(msg.sender, address(this), id, amount, "");

        stateSender.syncState(
            childERC1155Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, id, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155Deposit(address(rootToken), childToken, msg.sender, receiver, id, amount);
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 id, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC1155MetadataURI(rootToken).safeTransferFrom(address(this), receiver, id, amount, "");
        // slither-disable-next-line reentrancy-events
        emit ERC1155Withdraw(address(rootToken), childToken, withdrawer, receiver, id, amount);
    }
}
