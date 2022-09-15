// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MaticTransfer {
    function transferFrom(
        address token,
        address receiver,
        uint256 amount
    ) external {
        require(IERC20(token).transferFrom(msg.sender, receiver, amount), "TRANSFER_FAILED");
    }
}
