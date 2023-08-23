// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BasicGenesisProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) {}
}
