// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildGovernor, IVotesUpgradeable, TimelockControllerUpgradeable} from "contracts/child/governance/ChildGovernor.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildGovernorDeployer is Script {
    function deployChildGovernor(
        address proxyAdmin,
        IVotesUpgradeable token_,
        TimelockControllerUpgradeable timelock_,
        uint256 quorumNumerator_,
        address networkParams
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildGovernor.initialize,
            (token_, timelock_, quorumNumerator_, networkParams)
        );

        vm.startBroadcast();

        ChildGovernor childGovernor = new ChildGovernor();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childGovernor),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childGovernor);
        proxyAddr = address(proxy);
    }
}

contract DeployChildGovernor is ChildGovernorDeployer {
    function run(
        address proxyAdmin,
        IVotesUpgradeable token_,
        TimelockControllerUpgradeable timelock_,
        uint256 quorumNumerator_,
        address networkParams
    ) external returns (address logicAddr, address proxyAddr) {
        return deployChildGovernor(proxyAdmin, token_, timelock_, quorumNumerator_, networkParams);
    }
}
