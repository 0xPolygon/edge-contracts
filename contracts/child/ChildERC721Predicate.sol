// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/child/IChildERC721Predicate.sol";
import "../interfaces/child/IChildERC721.sol";
import "../interfaces/IStateSender.sol";
import "./System.sol";

/**
    @title ChildERC721Predicate
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Enables ERC721 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC721Predicate is IChildERC721Predicate, Initializable, System {
    /// @custom:security write-protection="onlySystemCall()"
    IStateSender public l2StateSender;
    /// @custom:security write-protection="onlySystemCall()"
    address public stateReceiver;
    /// @custom:security write-protection="onlySystemCall()"
    address public rootERC721Predicate;
    /// @custom:security write-protection="onlySystemCall()"
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    mapping(address => address) public rootTokenToChildToken;

    event L2ERC721Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId
    );
    event L2ERC721DepositBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds
    );
    event L2ERC721Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId
    );
    event L2ERC721WithdrawBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds
    );
    event L2TokenMapped(address indexed rootToken, address indexed childToken);

    modifier onlyValidToken(IChildERC721 childToken) {
        require(_verifyContract(childToken), "ChildERC721Predicate: NOT_CONTRACT");
        _;
    }

    /**
     * @notice Initilization function for ChildERC721Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newRootERC721Predicate Address of root ERC721 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) public virtual onlySystemCall initializer {
        _initialize(newL2StateSender, newStateReceiver, newRootERC721Predicate, newChildTokenTemplate);
    }

    /**
     * @notice Function to be used for token deposits
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == stateReceiver, "ChildERC721Predicate: ONLY_STATE_RECEIVER");
        require(sender == rootERC721Predicate, "ChildERC721Predicate: ONLY_ROOT_PREDICATE");

        if (bytes32(data[:32]) == DEPOSIT_SIG) {
            _beforeTokenDeposit();
            _deposit(data[32:]);
            _afterTokenDeposit();
        } else if (bytes32(data[:32]) == DEPOSIT_BATCH_SIG) {
            _beforeTokenDeposit();
            _depositBatch(data);
            _afterTokenDeposit();
        } else if (bytes32(data[:32]) == MAP_TOKEN_SIG) {
            _mapToken(data);
        } else {
            revert("ChildERC721Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to themselves on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param tokenId index of the NFT to withdraw
     */
    function withdraw(IChildERC721 childToken, uint256 tokenId) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, msg.sender, tokenId);
        _afterTokenWithdraw();
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to another address on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receiver Address of the receiver on the root chain
     * @param tokenId index of the NFT to withdraw
     */
    function withdrawTo(IChildERC721 childToken, address receiver, uint256 tokenId) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, receiver, tokenId);
        _afterTokenWithdraw();
    }

    /**
     * @notice Function to batch withdraw tokens from the withdrawer to other addresses on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receivers Addresses of the receivers on the root chain
     * @param tokenIds indices of the NFTs to withdraw
     */
    function withdrawBatch(
        IChildERC721 childToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) external {
        _beforeTokenWithdraw();
        _withdrawBatch(childToken, receivers, tokenIds);
        _afterTokenWithdraw();
    }

    /**
     * @notice Initilization function for ChildERC721Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newRootERC721Predicate Address of root ERC721 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) internal {
        require(
            newL2StateSender != address(0) &&
                newStateReceiver != address(0) &&
                newRootERC721Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "ChildERC721Predicate: BAD_INITIALIZATION"
        );
        l2StateSender = IStateSender(newL2StateSender);
        stateReceiver = newStateReceiver;
        rootERC721Predicate = newRootERC721Predicate;
        childTokenTemplate = newChildTokenTemplate;
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    function _withdraw(IChildERC721 childToken, address receiver, uint256 tokenId) private onlyValidToken(childToken) {
        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildERC721Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(childToken.burn(msg.sender, tokenId), "ChildERC721Predicate: BURN_FAILED");
        l2StateSender.syncState(
            rootERC721Predicate,
            abi.encode(WITHDRAW_SIG, rootToken, msg.sender, receiver, tokenId)
        );

        // slither-disable-next-line reentrancy-events
        emit L2ERC721Withdraw(rootToken, address(childToken), msg.sender, receiver, tokenId);
    }

    function _withdrawBatch(
        IChildERC721 childToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) private onlyValidToken(childToken) {
        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildERC721Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(receivers.length == tokenIds.length, "ChildERC721Predicate: INVALID_LENGTH");
        require(childToken.burnBatch(msg.sender, tokenIds), "ChildERC721Predicate: BURN_FAILED");
        l2StateSender.syncState(
            rootERC721Predicate,
            abi.encode(WITHDRAW_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds)
        );

        // slither-disable-next-line reentrancy-events
        emit L2ERC721WithdrawBatch(rootToken, address(childToken), msg.sender, receivers, tokenIds);
    }

    function _deposit(bytes calldata data) private {
        (address depositToken, address depositor, address receiver, uint256 tokenId) = abi.decode(
            data,
            (address, address, address, uint256)
        );

        IChildERC721 childToken = IChildERC721(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildERC721Predicate: UNMAPPED_TOKEN");
        // a mapped token should always pass specifications
        assert(_verifyContract(childToken));

        address rootToken = IChildERC721(childToken).rootToken();

        // a mapped token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC721(childToken).predicate() == address(this));
        require(IChildERC721(childToken).mint(receiver, tokenId), "ChildERC721Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit L2ERC721Deposit(depositToken, address(childToken), depositor, receiver, tokenId);
    }

    function _depositBatch(bytes calldata data) private {
        (, address depositToken, address depositor, address[] memory receivers, uint256[] memory tokenIds) = abi.decode(
            data,
            (bytes32, address, address, address[], uint256[])
        );

        IChildERC721 childToken = IChildERC721(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildERC721Predicate: UNMAPPED_TOKEN");
        // a mapped token should always pass specifications
        assert(_verifyContract(childToken));

        address rootToken = IChildERC721(childToken).rootToken();

        // a mapped token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC721(childToken).predicate() == address(this));
        require(IChildERC721(childToken).mintBatch(receivers, tokenIds), "ChildERC721Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit L2ERC721DepositBatch(depositToken, address(childToken), depositor, receivers, tokenIds);
    }

    /**
     * @notice Function to be used for mapping a root token to a child token
     * @dev Allows for 1-to-1 mappings for any root token to a child token
     */
    function _mapToken(bytes calldata data) private {
        (, address rootToken, string memory name, string memory symbol) = abi.decode(
            data,
            (bytes32, address, string, string)
        );
        assert(rootToken != address(0)); // invariant since root predicate performs the same check
        assert(rootTokenToChildToken[rootToken] == address(0)); // invariant since root predicate performs the same check
        IChildERC721 childToken = IChildERC721(
            Clones.cloneDeterministic(childTokenTemplate, keccak256(abi.encodePacked(rootToken)))
        );
        rootTokenToChildToken[rootToken] = address(childToken);
        childToken.initialize(rootToken, name, symbol);

        // slither-disable-next-line reentrancy-events
        emit L2TokenMapped(rootToken, address(childToken));
    }

    // slither does not handle try-catch blocks correctly
    // slither-disable-next-line unused-return
    function _verifyContract(IChildERC721 childToken) private view returns (bool) {
        if (address(childToken).code.length == 0) {
            return false;
        }
        // slither-disable-next-line uninitialized-local,variable-scope
        try childToken.supportsInterface(0x80ac58cd) returns (bool support) {
            return support;
        } catch {
            return false;
        }
    }
}
