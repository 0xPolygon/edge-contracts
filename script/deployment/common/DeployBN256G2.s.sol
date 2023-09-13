// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {BN256G2} from "contracts/common/BN256G2.sol";

abstract contract BN256G2Deployer is Script {
    function deployBN256G2() internal returns (address contractAddr) {
        vm.broadcast();
        BN256G2 bn256G2 = new BN256G2();

        contractAddr = address(bn256G2);
    }
}

contract DepoyBN256G2 is BN256G2Deployer {
    function run() external returns (address contractAddr) {
        return deployBN256G2();
    }
}
