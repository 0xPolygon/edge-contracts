// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/common/DeployBLS.s.sol";
import "script/deployment/common/DeployBN256G2.s.sol";
import "script/deployment/root/staking/DeployStakeManager.s.sol";

contract DeploySharedRootContracts is BLSDeployer, BN256G2Deployer, StakeManagerDeployer {
    using stdJson for string;

    address proxyAdmin;

    address bls;
    address bn256G2;
    address stakeManagerLogic;
    address stakeManagerProxy;

    function run() external {
        string memory config = vm.readFile("script/deployment/sharedRootContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["StakeManager"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        bls = deployBLS();

        bn256G2 = deployBN256G2();

        (stakeManagerLogic, stakeManagerProxy) = deployStakeManager(
            proxyAdmin,
            config.readAddress('["StakeManager"].newStakingToken')
        );

        console.log("Simulating...");
        console.log("");
        console.log("Expected addresses:");
        console.log("");
        console.log("ProxyAdmin");
        console.log("");
        console.log("Logic:", proxyAdmin);
        console.log("Proxy:", "Does not have a proxy");
        console.log("");
        console.log("");
        console.log("BLS");
        console.log("");
        console.log("Logic:", bls);
        console.log("Proxy:", "Does not have a proxy");
        console.log("");
        console.log("");
        console.log("BNG256G2");
        console.log("");
        console.log("Logic:", bn256G2);
        console.log("Proxy:", "Does not have a proxy");
        console.log("");
        console.log("");
        console.log("StakeManager");
        console.log("");
        console.log("Logic:", stakeManagerLogic);
        console.log("Proxy:", stakeManagerProxy);
        console.log("");
        console.log("");
        console.log("See logs for actual addresses.");
    }
}
