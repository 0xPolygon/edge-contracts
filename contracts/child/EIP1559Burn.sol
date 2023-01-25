// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IChildERC20.sol";
import "../interfaces/IChildERC20Predicate.sol";

contract EIP1559Burn is Initializable {
    using SafeERC20 for IChildERC20;

    IChildERC20Predicate public childERC20Predicate;
    address public burnDestination;
    IChildERC20 private constant NATIVE_TOKEN = IChildERC20(0x0000000000000000000000000000000000001010);

    event NativeTokenBurnt(address indexed burner, uint256 amount);

    function initialize(IChildERC20Predicate newChildERC20Predicate, address newBurnDestination) external initializer {
        require(address(newChildERC20Predicate) != address(0), "EIP1559Burn: BAD_INITIALIZATION");
        childERC20Predicate = newChildERC20Predicate;
        // slither-disable-next-line missing-zero-check
        burnDestination = newBurnDestination;
    }

    function withdraw() external {
        require(address(childERC20Predicate) != address(0), "EIP1559Burn: UNINITIALIZED");

        uint256 balance = address(this).balance;

        NATIVE_TOKEN.safeApprove(address(childERC20Predicate), balance);
        childERC20Predicate.withdrawTo(NATIVE_TOKEN, burnDestination, balance);
        // slither-disable-next-line reentrancy-events
        emit NativeTokenBurnt(msg.sender, balance);
    }
}
