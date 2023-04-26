// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAddressList {
    function readAddressList(address account) external view returns (uint256);
}
