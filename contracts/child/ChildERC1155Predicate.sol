// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IChildERC1155Predicate.sol";
import "../interfaces/IStateSender.sol";
import "../interfaces/IChildERC1155.sol";
import "./System.sol";

/**
    @title ChildERC1155Predicate
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Enables ERC1155 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC1155Predicate is IChildERC1155Predicate, Initializable, System {
    /// @custom:security write-protection="onlySystemCall()"
    IStateSender public l2StateSender;
    /// @custom:security write-protection="onlySystemCall()"
    address public stateReceiver;
    /// @custom:security write-protection="onlySystemCall()"
    address public rootERC1155Predicate;
    /// @custom:security write-protection="onlySystemCall()"
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    mapping(address => address) public rootTokenToChildToken;

    event L2ERC1155Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 id,
        uint256 amount
    );
    event L2ERC1155Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 id,
        uint256 amount
    );
    event L2TokenMapped(address indexed rootToken, address indexed childToken);

    modifier onlyValidToken(IChildERC1155 childToken) {
        _verifyContract(childToken);
        _;
    }

    /**
     * @notice Initilization function for ChildERC1155Predicate
     * @param newL2StateSender Address of L2StateSender to send exit information to
     * @param newStateReceiver Address of StateReceiver to receive deposit information from
     * @param newRootERC1155Predicate Address of root ERC1155 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @param newNativeTokenRootAddress Address of native token on root chain
     * @dev Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.
     */
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC1155Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress
    ) external onlySystemCall initializer {
        require(
            newL2StateSender != address(0) &&
                newStateReceiver != address(0) &&
                newRootERC1155Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "ChildERC1155Predicate: BAD_INITIALIZATION"
        );
        l2StateSender = IStateSender(newL2StateSender);
        stateReceiver = newStateReceiver;
        rootERC1155Predicate = newRootERC1155Predicate;
        childTokenTemplate = newChildTokenTemplate;
        if (newNativeTokenRootAddress != address(0)) {
            rootTokenToChildToken[newNativeTokenRootAddress] = NATIVE_TOKEN_CONTRACT;
            // slither-disable-next-line reentrancy-events
            emit L2TokenMapped(newNativeTokenRootAddress, NATIVE_TOKEN_CONTRACT);
        }
    }

    /**
     * @notice Function to be used for token deposits
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == stateReceiver, "ChildERC1155Predicate: ONLY_STATE_RECEIVER");
        require(sender == rootERC1155Predicate, "ChildERC1155Predicate: ONLY_ROOT_PREDICATE");

        if (bytes32(data[:32]) == DEPOSIT_SIG) {
            _deposit(data[32:]);
        } else if (bytes32(data[:32]) == MAP_TOKEN_SIG) {
            _mapToken(data);
        } else {
            revert("ChildERC1155Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Deploys a child ERC1155 token contract
     * @param rootToken Address of the ERC1155 token contract on root
     * @param salt Noise for address generation
     */
    function deployChildToken(address rootToken, bytes32 salt) external {
        //TODO
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to themselves on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param id Index of the NFT to withdraw
     * @param amount Amount of the NFT to withdraw
     */
    function withdraw(IChildERC1155 childToken, uint256 id, uint256 amount) external {
        _withdraw(childToken, msg.sender, id, amount);
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to another address on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receiver Address of the receiver on the root chain
     * @param id Index of the NFT to withdraw
     * @param amount Amount of NFT to withdraw
     */
    function withdrawTo(IChildERC1155 childToken, address receiver, uint256 id, uint256 amount) external {
        _withdraw(childToken, receiver, id, amount);
    }

    function _withdraw(
        IChildERC1155 childToken,
        address receiver,
        uint256 id,
        uint256 amount
    ) private onlyValidToken(childToken) {
        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildERC1155Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(childToken.burn(msg.sender, id, amount), "ChildERC1155Predicate: BURN_FAILED");
        l2StateSender.syncState(
            rootERC1155Predicate,
            abi.encode(WITHDRAW_SIG, rootToken, msg.sender, receiver, id, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit L2ERC1155Withdraw(rootToken, address(childToken), msg.sender, receiver, id, amount);
    }

    function _withdrawBatch(
        IChildERC1155 childToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {}

    function _deposit(bytes calldata data) private {
        (address depositToken, address depositor, address receiver, uint256 id, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256, uint256)
        );

        IChildERC1155 childToken = IChildERC1155(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildERC1155Predicate: UNMAPPED_TOKEN");
        _verifyContract(childToken);

        address rootToken = IChildERC1155(childToken).rootToken();

        // a mapped child token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC1155(childToken).predicate() == address(this));
        require(IChildERC1155(childToken).mint(receiver, id, amount), "ChildERC1155Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit L2ERC1155Deposit(depositToken, address(childToken), depositor, receiver, id, amount);
    }

    /**
     * @notice Function to be used for mapping a root token to a child token
     * @dev Allows for 1-to-1 mappings for any root token to a child token
     */
    function _mapToken(bytes calldata data) private {
        (, address rootToken, string memory name_, string memory uri_) = abi.decode(
            data,
            (bytes32, address, string, string)
        );
        assert(rootToken != address(0)); // invariant since root predicate performs the same check
        assert(rootTokenToChildToken[rootToken] == address(0)); // invariant since root predicate performs the same check
        IChildERC1155 childToken = IChildERC1155(
            Clones.cloneDeterministic(childTokenTemplate, keccak256(abi.encodePacked(rootToken)))
        );
        rootTokenToChildToken[rootToken] = address(childToken);
        childToken.initialize(rootToken, name_, uri_);

        // slither-disable-next-line reentrancy-events
        emit L2TokenMapped(rootToken, address(childToken));
    }

    function _verifyContract(IChildERC1155 childToken) private view {
        bool isERC1155;
        try childToken.supportsInterface(0xd9b67a26) returns (bool support) {
            isERC1155 = support;
        } catch (bytes memory /*lowLevelData*/) {
            isERC1155 = false;
        }
        require(isERC1155, "ChildERC721Predicate: NOT_CONTRACT");
    }
}
