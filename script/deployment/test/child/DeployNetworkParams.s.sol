// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {NetworkParams} from "contracts/child/NetworkParams.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract NetworkParamsDeployer is Script {
    function deployNetworkParams(
        address proxyAdmin,
        NetworkParams.InitParams memory initParams
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(NetworkParams.initialize, (initParams));

        vm.startBroadcast();

        NetworkParams networkParams = new NetworkParams();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(networkParams),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(networkParams);
        proxyAddr = address(proxy);
    }
}

contract DeployNetworkParams is NetworkParamsDeployer {
    function run(
        address proxyAdmin,
        NetworkParams.InitParams memory initParams
    ) external returns (address logicAddr, address proxyAddr) {
        return deployNetworkParams(proxyAdmin, initParams);
    }
}
