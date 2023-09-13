// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployCheckpointManager} from "script/deployment/root/DeployCheckpointManager.s.sol";

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IBLS} from "contracts/interfaces/common/IBLS.sol";
import {IBN256G2} from "contracts/interfaces/common/IBN256G2.sol";
import {ICheckpointManager} from "contracts/interfaces/root/ICheckpointManager.sol";

contract DeployCheckpointManagerTest is Test {
    DeployCheckpointManager private deployer;

    address logicAddr;
    address proxyAddr;

    CheckpointManager internal proxyAsCheckpointManager;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    IBLS newBls;
    IBN256G2 newBn256G2;
    uint256 chainId_;
    ICheckpointManager.Validator[] newValidatorSet;

    function setUp() public {
        deployer = new DeployCheckpointManager();

        proxyAdmin = makeAddr("proxyAdmin");
        newBls = IBLS(makeAddr("newBls"));
        newBn256G2 = IBN256G2(makeAddr("newBn256G2"));
        chainId_ = block.chainid;
        newValidatorSet.push(ICheckpointManager.Validator(makeAddr("newValidatorSet_0"), [uint(1), 2, 3, 4], 5));

        (logicAddr, proxyAddr) = deployer.run(proxyAdmin, newBls, newBn256G2, chainId_, newValidatorSet);
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
        proxyAsCheckpointManager.initialize(newBls, newBn256G2, chainId_, newValidatorSet);

        assertEq(
            vm.load(address(proxyAsCheckpointManager), bytes32(uint(6))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newBls)))
        );
        assertEq(
            vm.load(address(proxyAsCheckpointManager), bytes32(uint(7))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(newBn256G2)))
        );
        assertEq(proxyAsCheckpointManager.chainId(), chainId_);
        assertEq(proxyAsCheckpointManager.currentValidatorSetLength(), newValidatorSet.length);
        assertEq(proxyAsCheckpointManager.currentValidatorSetHash(), keccak256(abi.encode(newValidatorSet)));
        (address _address, uint votingPower) = proxyAsCheckpointManager.currentValidatorSet(0);
        assertEq(_address, newValidatorSet[0]._address);
        assertEq(votingPower, newValidatorSet[0].votingPower);
        assertEq(proxyAsCheckpointManager.totalVotingPower(), newValidatorSet[0].votingPower);
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
        proxyAsCheckpointManager = CheckpointManager(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
