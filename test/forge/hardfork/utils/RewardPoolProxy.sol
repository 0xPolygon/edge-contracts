// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// TODO: Use `initialize` instead of `constructor`.
contract RewardPoolProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, address newNetworkParams) TransparentUpgradeableProxy(logic, admin, "") {
        assembly {
            sstore(56, newNetworkParams)
        }
    }
}
