// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployChildMintableERC1155Predicate} from "script/deployment/root/DeployChildMintableERC1155Predicate.s.sol";

import {ChildMintableERC1155Predicate} from "contracts/root/ChildMintableERC1155Predicate.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployChildMintableERC1155PredicateTest is Test {
    DeployChildMintableERC1155Predicate private deployer;

    address logicAddr;
    address proxyAddr;

    ChildMintableERC1155Predicate internal proxyAsChildMintableERC1155Predicate;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStateSender;
    address newExitHelper;
    address newRootERC1155Predicate;
    address newChildTokenTemplate;

    function setUp() public {
        deployer = new DeployChildMintableERC1155Predicate();

        proxyAdmin = makeAddr("proxyAdmin");
        newStateSender = makeAddr("newStateSender");
        newExitHelper = makeAddr("newExitHelper");
        newRootERC1155Predicate = makeAddr("newRootERC1155Predicate");
        newChildTokenTemplate = makeAddr("newChildTokenTemplate");

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            newStateSender,
            newExitHelper,
            newRootERC1155Predicate,
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
        proxyAsChildMintableERC1155Predicate.initialize(
            newStateSender,
            newExitHelper,
            newRootERC1155Predicate,
            newChildTokenTemplate
        );

        assertEq(
            vm.load(address(proxyAsChildMintableERC1155Predicate), bytes32(uint(0))),
            bytes32(bytes.concat(hex"00000000000000000000", abi.encodePacked(newStateSender), hex"0001"))
        );
        assertEq(
            vm.load(address(proxyAsChildMintableERC1155Predicate), bytes32(uint(1))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newExitHelper)))
        );
        assertEq(
            vm.load(address(proxyAsChildMintableERC1155Predicate), bytes32(uint(2))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newRootERC1155Predicate)))
        );
        assertEq(
            vm.load(address(proxyAsChildMintableERC1155Predicate), bytes32(uint(3))),
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
        proxyAsChildMintableERC1155Predicate = ChildMintableERC1155Predicate(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
