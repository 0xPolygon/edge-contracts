// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStateReceiver {
    function onStateReceive(uint256 counter, address sender, bytes calldata data) external;
}
