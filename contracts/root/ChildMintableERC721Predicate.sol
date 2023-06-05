// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/root/IChildMintableERC721Predicate.sol";
import "../interfaces/child/IChildERC721.sol";
import "../interfaces/IStateSender.sol";

/**
    @title ChildMintableERC721Predicate
    @author Polygon Technology (@QEDK)
    @notice Enables mintable ERC721 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildMintableERC721Predicate is Initializable, IChildMintableERC721Predicate {
    IStateSender public stateSender;
    address public exitHelper;
    address public rootERC721Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    mapping(address => address) public rootTokenToChildToken;

    modifier onlyValidToken(IChildERC721 childToken) {
        require(_verifyContract(childToken), "ChildMintableERC721Predicate: NOT_CONTRACT");
        _;
    }

    /**
     * @notice Initilization function for ChildMintableERC721Predicate
     * @param newStateSender Address of StateSender to send exit information to
     * @param newExitHelper Address of ExitHelper to receive deposit information from
     * @param newRootERC721Predicate Address of root ERC721 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.
     */
    function initialize(
        address newStateSender,
        address newExitHelper,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) public virtual initializer {
        _initialize(newStateSender, newExitHelper, newRootERC721Predicate, newChildTokenTemplate);
    }

    /**
     * @notice Function to be used for token deposits
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "ChildMintableERC721Predicate: ONLY_EXIT_HELPER");
        require(sender == rootERC721Predicate, "ChildMintableERC721Predicate: ONLY_ROOT_PREDICATE");

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
            revert("ChildMintableERC721Predicate: INVALID_SIGNATURE");
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
     * @notice Initilization function for ChildMintableERC721Predicate
     * @param newStateSender Address of StateSender to send exit information to
     * @param newExitHelper Address of ExitHelper to receive deposit information from
     * @param newRootERC721Predicate Address of root ERC721 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newStateSender,
        address newExitHelper,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) internal virtual {
        require(
            newStateSender != address(0) &&
                newExitHelper != address(0) &&
                newRootERC721Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "ChildMintableERC721Predicate: BAD_INITIALIZATION"
        );
        stateSender = IStateSender(newStateSender);
        exitHelper = newExitHelper;
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

        require(
            rootTokenToChildToken[rootToken] == address(childToken),
            "ChildMintableERC721Predicate: UNMAPPED_TOKEN"
        );
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(childToken.burn(msg.sender, tokenId), "ChildMintableERC721Predicate: BURN_FAILED");
        stateSender.syncState(rootERC721Predicate, abi.encode(WITHDRAW_SIG, rootToken, msg.sender, receiver, tokenId));

        // slither-disable-next-line reentrancy-events
        emit MintableERC721Withdraw(rootToken, address(childToken), msg.sender, receiver, tokenId);
    }

    function _withdrawBatch(
        IChildERC721 childToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) private onlyValidToken(childToken) {
        address rootToken = childToken.rootToken();

        require(
            rootTokenToChildToken[rootToken] == address(childToken),
            "ChildMintableERC721Predicate: UNMAPPED_TOKEN"
        );
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(receivers.length == tokenIds.length, "ChildMintableERC721Predicate: INVALID_LENGTH");
        require(childToken.burnBatch(msg.sender, tokenIds), "ChildMintableERC721Predicate: BURN_FAILED");
        stateSender.syncState(
            rootERC721Predicate,
            abi.encode(WITHDRAW_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds)
        );

        // slither-disable-next-line reentrancy-events
        emit MintableERC721WithdrawBatch(rootToken, address(childToken), msg.sender, receivers, tokenIds);
    }

    function _deposit(bytes calldata data) private {
        (address depositToken, address depositor, address receiver, uint256 tokenId) = abi.decode(
            data,
            (address, address, address, uint256)
        );

        IChildERC721 childToken = IChildERC721(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildMintableERC721Predicate: UNMAPPED_TOKEN");
        // a mapped token should always pass specifications
        assert(_verifyContract(childToken));

        address rootToken = IChildERC721(childToken).rootToken();

        // a mapped token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC721(childToken).predicate() == address(this));
        require(IChildERC721(childToken).mint(receiver, tokenId), "ChildMintableERC721Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit MintableERC721Deposit(depositToken, address(childToken), depositor, receiver, tokenId);
    }

    function _depositBatch(bytes calldata data) private {
        (, address depositToken, address depositor, address[] memory receivers, uint256[] memory tokenIds) = abi.decode(
            data,
            (bytes32, address, address, address[], uint256[])
        );

        IChildERC721 childToken = IChildERC721(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildMintableERC721Predicate: UNMAPPED_TOKEN");
        // a mapped token should always pass specifications
        assert(_verifyContract(childToken));

        address rootToken = IChildERC721(childToken).rootToken();

        // a mapped token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC721(childToken).predicate() == address(this));
        require(IChildERC721(childToken).mintBatch(receivers, tokenIds), "ChildMintableERC721Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit MintableERC721DepositBatch(depositToken, address(childToken), depositor, receivers, tokenIds);
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
        emit MintableTokenMapped(rootToken, address(childToken));
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

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
