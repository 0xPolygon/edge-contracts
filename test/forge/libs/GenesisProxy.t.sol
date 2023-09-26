// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {GenesisProxy} from "contracts/lib/GenesisProxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract GenesisProxyTest is Test {
    address newOwner = makeAddr("newOwner");

    address logicAddr;
    address proxyAddr;

    DummyContract internal proxyAsDummyContract;
    GenesisProxy internal proxy;
    ITransparentUpgradeableProxy internal proxyWithAdminInterface;

    address proxyAdmin;

    function setUp() public {
        logicAddr = address(new DummyContract());

        proxyAdmin = makeAddr("proxyAdmin");

        proxyAddr = makeAddr("proxyAddr");
        vm.etch(proxyAddr, vm.getDeployedCode("GenesisProxy.sol"));
        _recordProxy(proxyAddr);

        proxy.protectSetUpProxy(proxyAdmin);
        vm.prank(proxyAdmin);
        proxy.setUpProxy(logicAddr, proxyAdmin, abi.encodeWithSelector(DummyContract.initialize.selector, newOwner));
    }

    function testRevert_constructor() public {
        vm.expectRevert();
        new GenesisProxy();
    }

    function test_RevertIfProtected_protectSetUpProxy() public {
        proxyAddr = makeAddr("proxyAddr random");
        vm.etch(proxyAddr, vm.getDeployedCode("GenesisProxy.sol"));
        _recordProxy(proxyAddr);

        proxy.protectSetUpProxy(proxyAdmin);

        vm.expectRevert("Already protected");
        proxy.protectSetUpProxy(proxyAdmin);

        vm.prank(proxyAdmin);
        proxy.setUpProxy(logicAddr, proxyAdmin, abi.encodeWithSelector(DummyContract.initialize.selector, newOwner));

        vm.expectRevert("Already protected");
        proxy.protectSetUpProxy(proxyAdmin);
    }

    function test_RevertIfUnauthorized_setUpProxy() public {
        proxyAddr = makeAddr("proxyAddr random");
        vm.etch(proxyAddr, vm.getDeployedCode("GenesisProxy.sol"));
        _recordProxy(proxyAddr);

        proxy.protectSetUpProxy(proxyAdmin);

        vm.expectRevert("Unauthorized");
        proxy.setUpProxy(address(0), address(0), "");
    }

    function test_RevertIfAlreadySetUp_setUpProxy() public {
        vm.expectRevert("Already set-up");
        proxy.setUpProxy(address(0), address(0), "");
    }

    function test_ProxyConfiguration() public {
        vm.startPrank(proxyAdmin);

        assertEq(proxyWithAdminInterface.admin(), proxyAdmin);
        assertEq(proxyWithAdminInterface.implementation(), logicAddr);

        vm.stopPrank();
    }

    function test_Delegation() public {
        assertEq(proxyAsDummyContract.owner(), newOwner);
    }

    function testLogicChange() public {
        address newLogicAddr = makeAddr("newLogicAddr");
        vm.etch(newLogicAddr, hex"00");

        vm.startPrank(proxyAdmin);

        proxyWithAdminInterface.upgradeTo(newLogicAddr);
        assertEq(proxyWithAdminInterface.implementation(), newLogicAddr);

        vm.stopPrank();
    }

    function testAdminChange() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(proxyAdmin);
        proxyWithAdminInterface.changeAdmin(newAdmin);

        vm.prank(newAdmin);
        assertEq(proxyWithAdminInterface.admin(), newAdmin);
    }

    function _recordProxy(address _proxyAddr) internal {
        proxyAsDummyContract = DummyContract(_proxyAddr);
        proxy = GenesisProxy(payable(address(_proxyAddr)));
        proxyWithAdminInterface = ITransparentUpgradeableProxy(_proxyAddr);
    }
}

contract DummyContract {
    address public owner;

    function initialize(address _owner) public {
        owner = _owner;
    }
}
