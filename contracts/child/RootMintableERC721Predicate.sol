// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/child/IRootMintableERC721Predicate.sol";
import "../interfaces/IStateSender.sol";
import "./System.sol";

// solhint-disable reason-string
contract RootMintableERC721Predicate is Initializable, ERC721Holder, System, IRootMintableERC721Predicate {
    IStateSender public l2StateSender;
    address public stateReceiver;
    address public childERC721Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;

    /**
     * @notice Initilization function for RootMintableERC721Predicate
     * @param newL2StateSender Address of L2StateSender to send deposit information to
     * @param newStateReceiver Address of StateReceiver to receive withdrawal information from
     * @param newChildERC721Predicate Address of child ERC721 predicate to communicate with
     * @param newChildTokenTemplate Address of child token template to calculate child token addresses
     * @dev Can only be called once.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) external virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newChildERC721Predicate, newChildTokenTemplate);
    }

    /**
     * @inheritdoc IStateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == stateReceiver, "RootMintableERC721Predicate: ONLY_STATE_RECEIVER");
        require(sender == childERC721Predicate, "RootMintableERC721Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _beforeTokenWithdraw();
            _withdraw(data[32:]);
            _afterTokenWithdraw();
        } else if (bytes32(data[:32]) == WITHDRAW_BATCH_SIG) {
            _beforeTokenWithdraw();
            _withdrawBatch(data);
            _afterTokenWithdraw();
        } else {
            revert("RootMintableERC721Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootMintableERC721Predicate
     */
    function deposit(IERC721Metadata rootToken, uint256 tokenId) external {
        _deposit(rootToken, msg.sender, tokenId);
    }

    /**
     * @inheritdoc IRootMintableERC721Predicate
     */
    function depositTo(IERC721Metadata rootToken, address receiver, uint256 tokenId) external {
        _deposit(rootToken, receiver, tokenId);
    }

    /**
     * @inheritdoc IRootMintableERC721Predicate
     */
    function depositBatch(
        IERC721Metadata rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) external {
        require(receivers.length == tokenIds.length, "RootMintableERC721Predicate: INVALID_LENGTH");
        _depositBatch(rootToken, receivers, tokenIds);
    }

    /**
     * @inheritdoc IRootMintableERC721Predicate
     */
    function mapToken(IERC721Metadata rootToken) public returns (address) {
        require(address(rootToken) != address(0), "RootMintableERC721Predicate: INVALID_TOKEN");
        require(rootTokenToChildToken[address(rootToken)] == address(0), "RootMintableERC721Predicate: ALREADY_MAPPED");

        address childPredicate = childERC721Predicate;

        address childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        l2StateSender.syncState(
            childPredicate,
            abi.encode(MAP_TOKEN_SIG, rootToken, rootToken.name(), rootToken.symbol())
        );
        // slither-disable-next-line reentrancy-events
        emit L2MintableTokenMapped(address(rootToken), childToken);
        return childToken;
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    function _initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newChildERC721Predicate,
        address newChildTokenTemplate
    ) internal {
        require(
            newL2StateSender != address(0) &&
                newStateReceiver != address(0) &&
                newChildERC721Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "RootMintableERC721Predicate: BAD_INITIALIZATION"
        );
        l2StateSender = IStateSender(newL2StateSender);
        stateReceiver = newStateReceiver;
        childERC721Predicate = newChildERC721Predicate;
        childTokenTemplate = newChildTokenTemplate;
    }

    function _deposit(IERC721Metadata rootToken, address receiver, uint256 tokenId) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        rootToken.safeTransferFrom(msg.sender, address(this), tokenId);

        l2StateSender.syncState(
            childERC721Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, tokenId)
        );
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC721Deposit(address(rootToken), childToken, msg.sender, receiver, tokenId);
        _afterTokenDeposit();
    }

    function _depositBatch(
        IERC721Metadata rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        for (uint256 i = 0; i < tokenIds.length; ) {
            rootToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        l2StateSender.syncState(
            childERC721Predicate,
            abi.encode(DEPOSIT_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds)
        );
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC721DepositBatch(address(rootToken), childToken, msg.sender, receivers, tokenIds);
        _afterTokenDeposit();
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 tokenId) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC721Metadata(rootToken).safeTransferFrom(address(this), receiver, tokenId);
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC721Withdraw(address(rootToken), childToken, withdrawer, receiver, tokenId);
    }

    function _withdrawBatch(bytes calldata data) private {
        (, address rootToken, address withdrawer, address[] memory receivers, uint256[] memory tokenIds) = abi.decode(
            data,
            (bytes32, address, address, address[], uint256[])
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens
        for (uint256 i = 0; i < tokenIds.length; ) {
            IERC721Metadata(rootToken).safeTransferFrom(address(this), receivers[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        // slither-disable-next-line reentrancy-events
        emit L2MintableERC721WithdrawBatch(address(rootToken), childToken, withdrawer, receivers, tokenIds);
    }

    function _getChildToken(IERC721Metadata rootToken) private returns (address childToken) {
        childToken = rootTokenToChildToken[address(rootToken)];
        if (childToken == address(0)) childToken = mapToken(IERC721Metadata(rootToken));
        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
