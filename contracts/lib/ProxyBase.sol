// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ProxyBase is TransparentUpgradeableProxy {
    // Required by compiler. Not meant to be used in the traditional way.
    constructor() TransparentUpgradeableProxy(address(this), msg.sender, "") {}

    function _setUpProxy(address logic, address admin, bytes memory data) internal {
        bytes32 setUpState;
        bytes32 setUpSlot = keccak256("ProxyBase _setUpProxy setUpSlot");

        // slither-disable-next-line assembly
        assembly {
            setUpState := sload(setUpSlot)
        }

        require(setUpState == "", "ProxyBase: Already set up.");

        // TransparentUpgradeableProxy
        _changeAdmin(admin);

        // ERC1967Proxy
        _upgradeToAndCall(logic, data, false);

        // slither-disable-next-line assembly
        assembly {
            sstore(setUpSlot, 0x01)
        }
    }
}
