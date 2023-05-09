// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract StateReceivingContract {
    uint256 public counter;

    function onStateReceive(uint256 /* id */, address /* sender */, bytes calldata data) external returns (bytes32) {
        counter += abi.decode(data, (uint256));
        return bytes32(counter);
    }
}
