// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract GenesisProxy is TransparentUpgradeableProxy {
    constructor() TransparentUpgradeableProxy(address(this), msg.sender, "") {}

    function _setUpProxy(address logic, address admin, bytes memory data) internal {
        bytes32 setUpState;
        bytes32 setUpSlot = keccak256("GenesisProxy setUpSlot");

        // slither-disable-next-line assembly
        assembly {
            setUpState := sload(setUpSlot)
        }

        require(setUpState == "", "GenesisProxy: Already set up.");

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
