// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/child/IChildERC20.sol";
import "../interfaces/child/IChildERC20Predicate.sol";

/**
    @title EIP1559Burn
    @author Polygon Technology (@QEDK)
    @notice Burns the native token on root chain as an ERC20
 */
contract EIP1559Burn is Initializable {
    IChildERC20Predicate public childERC20Predicate;
    address public burnDestination;
    IChildERC20 private constant NATIVE_TOKEN = IChildERC20(0x0000000000000000000000000000000000001010);

    event NativeTokenBurnt(address indexed burner, uint256 amount);

    // slither-disable-next-line locked-ether
    receive() external payable {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Initilization function for EIP1559 burn contract
     * @param newChildERC20Predicate Address of the ERC20 predicate on child chain
     * @param newBurnDestination Address on the root chain to burn the tokens and send to
     * @dev Can only be called once
     */
    function initialize(IChildERC20Predicate newChildERC20Predicate, address newBurnDestination) external initializer {
        require(address(newChildERC20Predicate) != address(0), "EIP1559Burn: BAD_INITIALIZATION");
        childERC20Predicate = newChildERC20Predicate;
        // slither-disable-next-line missing-zero-check
        burnDestination = newBurnDestination;
    }

    /**
     * @notice Function to burn native tokens on child chain and send them to burn destination on root
     * @dev Takes the entire current native token balance and burns it
     */
    function withdraw() external {
        require(address(childERC20Predicate) != address(0), "EIP1559Burn: UNINITIALIZED");

        uint256 balance = address(this).balance;

        childERC20Predicate.withdrawTo(NATIVE_TOKEN, burnDestination, balance);
        // slither-disable-next-line reentrancy-events
        emit NativeTokenBurnt(msg.sender, balance);
    }
}
