// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HFGenesisProxy.sol";

contract BasicHFGenesisProxy is HFGenesisProxy {
    function setUpProxy(address logic, address admin, bytes memory data) external {
        _setUpProxy(logic, admin, data);
    }
}
