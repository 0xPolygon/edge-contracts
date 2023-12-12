// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployBladeManager} from "script/deployment/bridge/DeployBladeManager.s.sol";

import {BladeManager, GenesisAccount} from "contracts/bridge/BladeManager.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployBladeManagerTest is Test {
    DeployBladeManager private deployer;

    address logicAddr;
    address proxyAddr;

    BladeManager internal proxyAsBladeManager;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStakeManager;
    address newBls;
    address newStateSender;
    address newMatic;
    address newChildValidatorSet;
    address newExitHelper;
    address newRootERC20Predicate;
    string newDomain;
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address jim = makeAddr("jim");

    function setUp() public {
        deployer = new DeployBladeManager();

        proxyAdmin = makeAddr("proxyAdmin");
        newRootERC20Predicate = makeAddr("newRootERC20Predicate");

        GenesisAccount[] memory validators = new GenesisAccount[](3);
        validators[0] = GenesisAccount({
            addr: bob,
            stakedTokens: 0,
            preminedTokens: 0,
            isValidator: true
        });
        validators[1] = GenesisAccount({
            addr: alice,
            stakedTokens: 0,
            preminedTokens: 0,
            isValidator: true
        });
        validators[2] = GenesisAccount({
            addr: jim,
            stakedTokens: 0,
            preminedTokens: 0,
            isValidator: true
        });

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            newRootERC20Predicate,
            validators
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
        proxyAsBladeManager.initialize(
            newRootERC20Predicate,
            new GenesisAccount[](0)
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
        proxyAsBladeManager = BladeManager(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
