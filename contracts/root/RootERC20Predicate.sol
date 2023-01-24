// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStateSender.sol";

contract RootERC20Predicate is Initializable {
    using SafeERC20 for IERC20;

    struct ERC20BridgeEvent {
        address rootToken;
        address childToken;
        address sender;
        address receiver;
    }

    IStateSender public stateSender;
    address public exitHelper;
    address public childERC20Predicate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");

    event ERC20Deposit(ERC20BridgeEvent indexed deposit, uint256 amount);
    event ERC20Withdraw(ERC20BridgeEvent indexed withdrawal, uint256 amount);

    function initialize(
        address newStateSender,
        address newExitHelper,
        address newChildERC20Predicate
    ) external initializer {
        require(
            newStateSender != address(0) && newExitHelper != address(0) && newChildERC20Predicate != address(0),
            "RootERC20Predicate: BAD_INITIALIZATION"
        );
        stateSender = IStateSender(newStateSender);
        exitHelper = newExitHelper;
        childERC20Predicate = newChildERC20Predicate;
    }

    function deposit(IERC20 rootToken, address childToken, uint256 amount) external {
        _deposit(rootToken, childToken, msg.sender, amount);
    }

    function depositTo(IERC20 rootToken, address childToken, address receiver, uint256 amount) external {
        _deposit(rootToken, childToken, receiver, amount);
    }

    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "RootERC20Predicate: ONLY_EXIT_HELPER");
        require(sender == childERC20Predicate, "RootERC20Predicate: ONLY_CHILD_PREDICATE");

        (
            bytes32 signature,
            address rootToken,
            address childToken,
            address withdrawer,
            address receiver,
            uint256 amount
        ) = abi.decode(data, (bytes32, address, address, address, address, uint256));

        if (signature == WITHDRAW_SIG) {
            _withdraw(IERC20(rootToken), childToken, withdrawer, receiver, amount);
        } else {
            revert("RootERC20Predicate: INVALID_SIGNATURE");
        }
    }

    function _deposit(IERC20 rootToken, address childToken, address receiver, uint256 amount) private {
        rootToken.safeTransferFrom(msg.sender, address(this), amount);

        stateSender.syncState(
            childERC20Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, childToken, msg.sender, receiver, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit ERC20Deposit(ERC20BridgeEvent(address(rootToken), childToken, msg.sender, receiver), amount);
    }

    function _withdraw(
        IERC20 rootToken,
        address childToken,
        address withdrawer,
        address receiver,
        uint256 amount
    ) private {
        rootToken.safeTransfer(receiver, amount);
        // slither-disable-next-line reentrancy-events
        emit ERC20Withdraw(ERC20BridgeEvent(address(rootToken), childToken, withdrawer, receiver), amount);
    }
}
