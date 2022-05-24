// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract StateReceivingContract {
    uint256 public counter;

    function onStateReceive(
        uint256, /* id */
        address, /* sender */
        bytes calldata data
    ) external {
        counter = abi.decode(data, (uint256));
    }
}
