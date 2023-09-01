// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployStakeManager} from "script/deployment/root/staking/DeployStakeManager.s.sol";

import {StakeManager} from "contracts/root/staking/StakeManager.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployStakeManagerTest is Test {
    DeployStakeManager private deployer;

    address logicAddr;
    address proxyAddr;

    StakeManager internal proxyAsStakeManager;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStakingToken;

    function setUp() public {
        deployer = new DeployStakeManager();

        proxyAdmin = makeAddr("proxyAdmin");
        newStakingToken = makeAddr("newStakingToken");

        (logicAddr, proxyAddr) = deployer.run(proxyAdmin, newStakingToken);
        _recordProxy(proxyAddr);
    }

    function testRun() public {
        vm.startPrank(proxyAdmin);

        assertEq(proxy.admin(), proxyAdmin);
        assertEq(proxy.implementation(), logicAddr);

        vm.stopPrank();
    }

    function testInitialization() public {
        vm.expectRevert("Initializable: contract is already initialized");
        proxyAsStakeManager.initialize(newStakingToken);

        assertEq(
            vm.load(address(proxyAsStakeManager), bytes32(uint(109))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newStakingToken)))
        );
    }

    function testLogicChange() public {
        address newLogicAddr = makeAddr("newLogicAddr");
        vm.etch(newLogicAddr, hex"00");

        vm.startPrank(proxyAdmin);

        proxy.upgradeTo(newLogicAddr);
        assertEq(proxy.implementation(), newLogicAddr);

        vm.stopPrank();
    }

    function testAdminChange() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(proxyAdmin);
        proxy.changeAdmin(newAdmin);

        vm.prank(newAdmin);
        assertEq(proxy.admin(), newAdmin);
    }

    function _recordProxy(address _proxyAddr) internal {
        proxyAsStakeManager = StakeManager(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
