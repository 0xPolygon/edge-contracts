// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract HPCore is TransparentUpgradeableProxy {
    constructor() TransparentUpgradeableProxy(address(this), msg.sender, "") {}

    function _setUpProxy(address logic, address admin) internal {
        bytes32 setUpState;
        bytes32 setUpSlot = keccak256("GenesisProxy _setUpProxy setUpSlot");

        // slither-disable-next-line assembly
        assembly {
            setUpState := sload(setUpSlot)
        }

        require(setUpState == "", "HFGenesisProxy: Already set up.");

        // TransparentUpgradeableProxy
        _changeAdmin(admin);

        // ERC1967Proxy
        _upgradeTo(logic);

        // slither-disable-next-line assembly
        assembly {
            sstore(setUpSlot, 0x01)
        }
    }
}
