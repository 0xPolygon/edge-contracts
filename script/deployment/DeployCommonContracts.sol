// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/common/DeployBLS.s.sol";
import "script/deployment/common/DeployBN256G2.s.sol";

contract DeployCommonContracts is BLSDeployer, BN256G2Deployer {
    using stdJson for string;

    function run() external returns (address proxyAdmin, address bls, address bn256G2) {
        string memory config = vm.readFile("script/deployment/commonContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        bls = deployBLS();

        bn256G2 = deployBN256G2();
    }
}
