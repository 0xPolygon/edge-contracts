// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployRootERC721Predicate} from "script/deployment/root/DeployRootERC721Predicate.s.sol";

import {RootERC721Predicate} from "contracts/root/RootERC721Predicate.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployRootERC721PredicateTest is Test {
    DeployRootERC721Predicate private deployer;

    address logicAddr;
    address proxyAddr;

    RootERC721Predicate internal proxyAsRootERC721Predicate;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStateSender;
    address newExitHelper;
    address newChildERC721Predicate;
    address newChildTokenTemplate;

    function setUp() public {
        deployer = new DeployRootERC721Predicate();

        proxyAdmin = makeAddr("proxyAdmin");
        newStateSender = makeAddr("newStateSender");
        newExitHelper = makeAddr("newExitHelper");
        newChildERC721Predicate = makeAddr("newChildERC721Predicate");
        newChildTokenTemplate = makeAddr("newChildTokenTemplate");

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            newStateSender,
            newExitHelper,
            newChildERC721Predicate,
            newChildTokenTemplate
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
        proxyAsRootERC721Predicate.initialize(
            newStateSender,
            newExitHelper,
            newChildERC721Predicate,
            newChildTokenTemplate
        );

        assertEq(
            vm.load(address(proxyAsRootERC721Predicate), bytes32(uint(0))),
            bytes32(bytes.concat(hex"00000000000000000000", abi.encodePacked(newStateSender), hex"0001"))
        );
        assertEq(
            vm.load(address(proxyAsRootERC721Predicate), bytes32(uint(1))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newExitHelper)))
        );
        assertEq(
            vm.load(address(proxyAsRootERC721Predicate), bytes32(uint(2))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newChildERC721Predicate)))
        );
        assertEq(
            vm.load(address(proxyAsRootERC721Predicate), bytes32(uint(3))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newChildTokenTemplate)))
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
        proxyAsRootERC721Predicate = RootERC721Predicate(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
