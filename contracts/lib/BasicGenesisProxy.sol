// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenesisProxy.sol";

contract BasicGenesisProxy is GenesisProxy {
    function setUpProxy(address logic, address admin, bytes memory data) external {
        _setUpProxy(logic, admin, data);
    }
}
