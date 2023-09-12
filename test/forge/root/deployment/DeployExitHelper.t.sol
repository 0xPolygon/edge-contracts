// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployExitHelper} from "script/deployment/root/DeployExitHelper.s.sol";

import {ExitHelper} from "contracts/root/ExitHelper.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ICheckpointManager} from "contracts/interfaces/root/ICheckpointManager.sol";

contract DeployExitHelperTest is Test {
    DeployExitHelper private deployer;

    address logicAddr;
    address proxyAddr;

    ExitHelper internal proxyAsExitHelper;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    ICheckpointManager checkpointManager;

    function setUp() public {
        deployer = new DeployExitHelper();

        proxyAdmin = makeAddr("proxyAdmin");
        checkpointManager = ICheckpointManager(makeAddr("checkpointManager"));
        vm.etch(address(checkpointManager), hex"00");

        (logicAddr, proxyAddr) = deployer.run(proxyAdmin, checkpointManager);
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
        proxyAsExitHelper.initialize(checkpointManager);

        assertEq(
            vm.load(address(proxyAsExitHelper), bytes32(uint(2))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(checkpointManager)))
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
        proxyAsExitHelper = ExitHelper(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
