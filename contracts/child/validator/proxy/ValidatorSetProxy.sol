// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/GenesisProxy.sol";

contract ValidatorSetProxy is GenesisProxy {
    function setUpProxy(address logic, address admin, bytes memory data, address newNetworkParams) external {
        _setUpProxy(logic, admin, data);

        // slither-disable-next-line assembly
        assembly {
            sstore(209, newNetworkParams)
        }
    }
}
