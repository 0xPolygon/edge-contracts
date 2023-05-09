// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockNativeERC20Transfer {
    function transferFrom(address token, address receiver, uint256 amount) external {
        require(IERC20(token).transferFrom(msg.sender, receiver, amount), "TRANSFER_FAILED");
    }
}
