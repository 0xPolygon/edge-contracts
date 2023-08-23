// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/lib/hardfork/HFGenesisProxy.sol";
import {NetworkParams} from "contracts/child/NetworkParams.sol";

contract NetworkParamsHFGenesisProxy is HFGenesisProxy {
    function setUpProxy(address logic, address admin, NetworkParams.InitParams memory initParams) external {
        _setUpProxy(logic, admin);

        // slither-disable-next-line assembly, too-many-digits
        assembly {
            sstore(0, 0x0000000000000000000000000000000000000000000000000000000000000000)
            sstore(1, 0x0000000000000000000000000000000000000000000000000000000000000000)
            sstore(2, 0x0000000000000000000000000000000000000000000000000000000000000000)
            sstore(3, 0x0000000000000000000000000000000000000000000000000000000000000000)
            sstore(4, 0x0000000000000000000000000000000000000000000000000000000000000000)
        }

        NetworkParams(address(this)).initialize(initParams);
    }
}
