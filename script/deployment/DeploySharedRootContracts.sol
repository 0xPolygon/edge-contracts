// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/common/DeployBLS.s.sol";
import "script/deployment/common/DeployBN256G2.s.sol";
import "script/deployment/root/staking/DeployStakeManager.s.sol";

contract DeploySharedRootContracts is BLSDeployer, BN256G2Deployer, StakeManagerDeployer {
    using stdJson for string;

    function run()
        external
        returns (address proxyAdmin, address bls, address bn256G2, address stakeManagerLogic, address stakeManagerProxy)
    {
        string memory config = vm.readFile("script/deployment/sharedRootContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        bls = deployBLS();

        bn256G2 = deployBN256G2();

        (stakeManagerLogic, stakeManagerProxy) = deployStakeManager(
            proxyAdmin,
            config.readAddress('["StakeManager"].newStakingToken')
        );
    }
}
