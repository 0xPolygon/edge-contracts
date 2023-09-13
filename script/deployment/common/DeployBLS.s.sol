// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {BLS} from "contracts/common/BLS.sol";

abstract contract BLSDeployer is Script {
    function deployBLS() internal returns (address contractAddr) {
        vm.broadcast();
        BLS bls = new BLS();

        contractAddr = address(bls);
    }
}

contract DepoyBLS is BLSDeployer {
    function run() external returns (address contractAddr) {
        return deployBLS();
    }
}
