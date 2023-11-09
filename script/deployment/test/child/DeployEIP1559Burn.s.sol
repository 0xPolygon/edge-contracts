// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {EIP1559Burn, IChildERC20Predicate} from "contracts/child/EIP1559Burn.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract EIP1559BurnDeployer is Script {
    function deployEIP1559Burn(
        address proxyAdmin,
        IChildERC20Predicate newChildERC20Predicate,
        address newBurnDestination
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(EIP1559Burn.initialize, (newChildERC20Predicate, newBurnDestination));

        vm.startBroadcast();

        EIP1559Burn eip1559Burn = new EIP1559Burn();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(eip1559Burn), proxyAdmin, initData);

        vm.stopBroadcast();

        logicAddr = address(eip1559Burn);
        proxyAddr = address(proxy);
    }
}

contract DeployEIP1559Burn is EIP1559BurnDeployer {
    function run(
        address proxyAdmin,
        IChildERC20Predicate newChildERC20Predicate,
        address newBurnDestination
    ) external returns (address logicAddr, address proxyAddr) {
        return deployEIP1559Burn(proxyAdmin, newChildERC20Predicate, newBurnDestination);
    }
}
