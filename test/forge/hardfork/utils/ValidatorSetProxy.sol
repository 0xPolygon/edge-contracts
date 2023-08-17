// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {console2 as console} from "forge-std/console2.sol";

// TODO: Use `initialize` instead of `constructor`.
contract ValidatorSetProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, address newNetworkParams) TransparentUpgradeableProxy(logic, admin, "") {
        assembly {
            sstore(209, newNetworkParams)
        }
    }
}
