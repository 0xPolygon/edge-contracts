// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/root/IRootERC1155Predicate.sol";
import "../interfaces/root/IL2StateReceiver.sol";
import "../interfaces/IStateSender.sol";

// solhint-disable reason-string
contract RootERC1155Predicate is IRootERC1155Predicate, IL2StateReceiver, Initializable, ERC1155Holder {
    IStateSender public stateSender;
    address public exitHelper;
    address public childERC1155Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;

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
        address newChildTokenTemplate
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
    }

    /**
     * @inheritdoc IL2StateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "RootERC1155Predicate: ONLY_EXIT_HELPER");
        require(sender == childERC1155Predicate, "RootERC1155Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _withdraw(data[32:]);
        } else if (bytes32(data[:32]) == WITHDRAW_BATCH_SIG) {
            _withdrawBatch(data);
        } else {
            revert("RootERC1155Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function deposit(IERC1155MetadataURI rootToken, uint256 tokenId, uint256 amount) external {
        _deposit(rootToken, msg.sender, tokenId, amount);
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function depositTo(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) external {
        _deposit(rootToken, receiver, tokenId, amount);
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        require(
            receivers.length == tokenIds.length && receivers.length == amounts.length,
            "RootERC1155Predicate: INVALID_LENGTH"
        );
        _depositBatch(rootToken, receivers, tokenIds, amounts);
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function mapToken(IERC1155MetadataURI rootToken) public returns (address childToken) {
        require(address(rootToken) != address(0), "RootERC1155Predicate: INVALID_TOKEN");
        require(rootTokenToChildToken[address(rootToken)] == address(0), "RootERC1155Predicate: ALREADY_MAPPED");

        childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childERC1155Predicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        string memory uri = "";
        // slither does not deal well with try-catch: https://github.com/crytic/slither/issues/982
        // slither-disable-next-line uninitialized-local,unused-return,variable-scope
        try rootToken.uri(0) returns (string memory tokenUri) {
            uri = tokenUri;
        } catch {}

        stateSender.syncState(childERC1155Predicate, abi.encode(MAP_TOKEN_SIG, rootToken, uri));
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);
    }

    function _deposit(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) private {
        address childToken = _getChildToken(rootToken);

        rootToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        stateSender.syncState(
            childERC1155Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, tokenId, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155Deposit(address(rootToken), childToken, msg.sender, receiver, tokenId, amount);
    }

    function _depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        address childToken = _getChildToken(rootToken);

        for (uint256 i = 0; i < tokenIds.length; ) {
            rootToken.safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }

        stateSender.syncState(
            childERC1155Predicate,
            abi.encode(DEPOSIT_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds, amounts)
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155DepositBatch(address(rootToken), childToken, msg.sender, receivers, tokenIds, amounts);
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 tokenId, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC1155MetadataURI(rootToken).safeTransferFrom(address(this), receiver, tokenId, amount, "");
        // slither-disable-next-line reentrancy-events
        emit ERC1155Withdraw(address(rootToken), childToken, withdrawer, receiver, tokenId, amount);
    }

    function _withdrawBatch(bytes calldata data) private {
        (
            ,
            address rootToken,
            address withdrawer,
            address[] memory receivers,
            uint256[] memory tokenIds,
            uint256[] memory amounts
        ) = abi.decode(data, (bytes32, address, address, address[], uint256[], uint256[]));
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens
        for (uint256 i = 0; i < tokenIds.length; ) {
            IERC1155MetadataURI(rootToken).safeTransferFrom(address(this), receivers[i], tokenIds[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }
        // slither-disable-next-line reentrancy-events
        emit ERC1155WithdrawBatch(address(rootToken), childToken, withdrawer, receivers, tokenIds, amounts);
    }

    function _getChildToken(IERC1155MetadataURI rootToken) private returns (address childToken) {
        childToken = rootTokenToChildToken[address(rootToken)];
        if (childToken == address(0)) childToken = mapToken(IERC1155MetadataURI(rootToken));
        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist
    }
}
