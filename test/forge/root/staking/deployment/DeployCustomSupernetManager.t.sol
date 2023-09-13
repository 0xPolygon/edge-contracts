// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployCustomSupernetManager} from "script/deployment/root/staking/DeployCustomSupernetManager.s.sol";

import {CustomSupernetManager} from "contracts/root/staking/CustomSupernetManager.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployCustomSupernetManagerTest is Test {
    DeployCustomSupernetManager private deployer;

    address logicAddr;
    address proxyAddr;

    CustomSupernetManager internal proxyAsCustomSupernetManager;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStakeManager;
    address newBls;
    address newStateSender;
    address newMatic;
    address newChildValidatorSet;
    address newExitHelper;
    string newDomain;

    function setUp() public {
        deployer = new DeployCustomSupernetManager();

        proxyAdmin = makeAddr("proxyAdmin");
        newStakeManager = makeAddr("newStakeManager");
        newBls = makeAddr("newBls");
        newStateSender = makeAddr("newStateSender");
        newMatic = makeAddr("newMatic");
        newChildValidatorSet = makeAddr("newChildValidatorSet");
        newExitHelper = makeAddr("newExitHelper");
        newDomain = "newDomain";

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            newStakeManager,
            newBls,
            newStateSender,
            newMatic,
            newChildValidatorSet,
            newExitHelper,
            newDomain
        );
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
        proxyAsCustomSupernetManager.initialize(
            newStakeManager,
            newBls,
            newStateSender,
            newMatic,
            newChildValidatorSet,
            newExitHelper,
            newDomain
        );

        assertEq(
            vm.load(address(proxyAsCustomSupernetManager), bytes32(uint(151))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newStakeManager)))
        );
        assertEq(
            vm.load(address(proxyAsCustomSupernetManager), bytes32(uint(203))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newBls)))
        );
        assertEq(
            vm.load(address(proxyAsCustomSupernetManager), bytes32(uint(204))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newStateSender)))
        );
        assertEq(
            vm.load(address(proxyAsCustomSupernetManager), bytes32(uint(205))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newMatic)))
        );
        assertEq(
            vm.load(address(proxyAsCustomSupernetManager), bytes32(uint(206))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newChildValidatorSet)))
        );
        assertEq(
            vm.load(address(proxyAsCustomSupernetManager), bytes32(uint(207))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newExitHelper)))
        );
        assertEq(proxyAsCustomSupernetManager.domain(), keccak256(abi.encodePacked(newDomain)));
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
        proxyAsCustomSupernetManager = CustomSupernetManager(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
