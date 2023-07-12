// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/child/IRootMintableERC1155Predicate.sol";
import "../interfaces/IStateSender.sol";

// solhint-disable reason-string
contract RootMintableERC1155Predicate is Initializable, ERC1155Holder, IRootMintableERC1155Predicate {
    IStateSender public l2StateSender;
    address public stateReceiver;
    address public childERC1155Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;

    /**
     * @notice Initilization function for RootMintableERC1155Predicate
     * @param newL2StateSender Address of L2StateSender to send deposit information to
     * @param newStateReceiver Address of StateReceiver to receive withdrawal information from
     * @param newChildERC1155Predicate Address of child ERC1155 predicate to communicate with
     * @dev Can only be called once.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate
    ) external initializer {
        _initialize(newL2StateSender, newStateReceiver, newChildERC1155Predicate, newChildTokenTemplate);
    }

    /**
     * @inheritdoc IStateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == stateReceiver, "RootMintableERC1155Predicate: ONLY_STATE_RECEIVER");
        require(sender == childERC1155Predicate, "RootMintableERC1155Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _beforeTokenWithdraw();
            _withdraw(data[32:]);
            _afterTokenWithdraw();
        } else if (bytes32(data[:32]) == WITHDRAW_BATCH_SIG) {
            _beforeTokenWithdraw();
            _withdrawBatch(data);
            _afterTokenWithdraw();
        } else {
            revert("RootMintableERC1155Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootMintableERC1155Predicate
     */
    function deposit(IERC1155MetadataURI rootToken, uint256 tokenId, uint256 amount) external {
        _deposit(rootToken, msg.sender, tokenId, amount);
    }

    /**
     * @inheritdoc IRootMintableERC1155Predicate
     */
    function depositTo(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) external {
        _deposit(rootToken, receiver, tokenId, amount);
    }

    /**
     * @inheritdoc IRootMintableERC1155Predicate
     */
    function depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        require(
            receivers.length == tokenIds.length && receivers.length == amounts.length,
            "RootMintableERC1155Predicate: INVALID_LENGTH"
        );
        _depositBatch(rootToken, receivers, tokenIds, amounts);
    }

    /**
     * @inheritdoc IRootMintableERC1155Predicate
     */
    function mapToken(IERC1155MetadataURI rootToken) public returns (address childToken) {
        require(address(rootToken) != address(0), "RootMintableERC1155Predicate: INVALID_TOKEN");
        require(
            rootTokenToChildToken[address(rootToken)] == address(0),
            "RootMintableERC1155Predicate: ALREADY_MAPPED"
        );

        address childPredicate = childERC1155Predicate;

        childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        string memory uri = "";
        // slither does not deal well with try-catch: https://github.com/crytic/slither/issues/982
        // slither-disable-next-line uninitialized-local,unused-return,variable-scope
        try rootToken.uri(0) returns (string memory tokenUri) {
            uri = tokenUri;
        } catch {}

        l2StateSender.syncState(childPredicate, abi.encode(MAP_TOKEN_SIG, rootToken, uri));
        // slither-disable-next-line reentrancy-events
        emit L2MintableTokenMapped(address(rootToken), childToken);
    }

    function _initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC1155Predicate,
        address newChildTokenTemplate
    ) internal {
        require(
            newL2StateSender != address(0) &&
                newStateReceiver != address(0) &&
                newChildERC1155Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "RootMintableERC1155Predicate: BAD_INITIALIZATION"
        );
        l2StateSender = IStateSender(newL2StateSender);
        stateReceiver = newStateReceiver;
        childERC1155Predicate = newChildERC1155Predicate;
        childTokenTemplate = newChildTokenTemplate;
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    function _deposit(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        rootToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        l2StateSender.syncState(
            childERC1155Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, tokenId, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC1155Deposit(address(rootToken), childToken, msg.sender, receiver, tokenId, amount);
        _afterTokenDeposit();
    }

    function _depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        for (uint256 i = 0; i < tokenIds.length; ) {
            rootToken.safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }

        l2StateSender.syncState(
            childERC1155Predicate,
            abi.encode(DEPOSIT_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds, amounts)
        );
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC1155DepositBatch(address(rootToken), childToken, msg.sender, receivers, tokenIds, amounts);
        _afterTokenDeposit();
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
        emit L2MintableERC1155Withdraw(address(rootToken), childToken, withdrawer, receiver, tokenId, amount);
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
        emit L2MintableERC1155WithdrawBatch(address(rootToken), childToken, withdrawer, receivers, tokenIds, amounts);
    }

    function _getChildToken(IERC1155MetadataURI rootToken) private returns (address childToken) {
        childToken = rootTokenToChildToken[address(rootToken)];
        if (childToken == address(0)) childToken = mapToken(IERC1155MetadataURI(rootToken));
        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
