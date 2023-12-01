// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
    @title GenesisProxy
    @author Polygon Technology
    @notice wrapper for OpenZeppelin's Transparent Upgreadable Proxy, intended for use during genesis for genesis contracts
    @notice one GenesisProxy should be deployed for each genesis contract
 */
contract GenesisProxy is TransparentUpgradeableProxy {
    // keccak256("GenesisProxy INITIATOR_SLOT")
    bytes32 private constant INITIATOR_SLOT = hex"16561015e0650c143c10fb1907c52a56b654e2f0922ca3245bde5beff81a333d";

    constructor() TransparentUpgradeableProxy(address(0), address(0), "") {
        revert();
    }

    function protectSetUpProxy(address initiator) external {
        bytes32 protected;

        // slither-disable-next-line assembly
        assembly {
            protected := sload(INITIATOR_SLOT)
            sstore(INITIATOR_SLOT, initiator)
        }

        require(protected == "", "Already protected");
    }

    function setUpProxy(address logic, address admin, bytes memory data) external {
        address initiator;

        // slither-disable-next-line assembly
        assembly {
            initiator := sload(INITIATOR_SLOT)
        }

        require(initiator != address(1), "Already set-up");

        require(msg.sender == initiator, "Unauthorized");

        // TransparentUpgradeableProxy constructor
        _changeAdmin(admin);

        // ERC1967Proxy constructor
        _upgradeToAndCall(logic, data, false);

        // slither-disable-next-line assembly
        assembly {
            sstore(INITIATOR_SLOT, 1)
        }
    }
}
