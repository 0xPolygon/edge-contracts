// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IStateSender.sol";
import "../interfaces/IChildERC20.sol";
import "../interfaces/IStateReceiver.sol";

contract ChildERC20Predicate is IStateReceiver, Initializable {
    using SafeERC20 for IERC20;

    struct ERC20BridgeEvent {
        address rootToken;
        address childToken;
        address sender;
        address receiver;
    }

    IStateSender public l2StateSender;
    address public stateReceiver;
    address public rootERC20Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");

    mapping(address => address) public childTokenToRootToken;

    event L2ERC20Deposit(ERC20BridgeEvent indexed deposit, uint256 amount);
    event L2ERC20Withdraw(ERC20BridgeEvent indexed withdrawal, uint256 amount);

    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate
    ) external initializer {
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
    }

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

    function withdraw(IChildERC20 childToken, uint256 amount) external {
        _withdraw(childToken, msg.sender, amount);
    }

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
