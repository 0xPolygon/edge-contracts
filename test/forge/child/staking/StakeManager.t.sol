// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {StakeManager} from "contracts/blade/staking/StakeManager.sol";
import {EpochManager} from "contracts/blade/validator/EpochManager.sol";
import {GenesisValidator} from "contracts/interfaces/blade/staking/IStakeManager.sol";
import {Epoch} from "contracts/interfaces/blade/validator/IEpochManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";

abstract contract Uninitialized is Test {
    address public constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    MockERC20 token;
    StakeManager stakeManager;

    address blsAddr;
    EpochManager epochManager;
    string testDomain = "DUMMY_DOMAIN";

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address jim = makeAddr("jim");
    address rewardWallet = makeAddr("rewardWallet");

    uint256 newStakeAmount = 100;
    uint256 newUnstakeAmount = 150;
    uint256 bobInitialStake = 400;
    uint256 aliceInitialStake = 200;
    uint256 jimInitialStake = 100;

    function setUp() public virtual {
        token = new MockERC20();
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);
        token.mint(jim, 1000 ether);

        stakeManager = new StakeManager();
        epochManager = new EpochManager();

        vm.prank(alice);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(bob);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(jim);
        token.approve(address(stakeManager), type(uint256).max);

        blsAddr = makeAddr("bls");

        epochManager.initialize(address(stakeManager), address(token), rewardWallet, 1 ether, 64);
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        GenesisValidator[] memory validators = new GenesisValidator[](3);
        validators[0] = GenesisValidator({addr: bob, stake: bobInitialStake, blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]});
        validators[1] = GenesisValidator({addr: alice, stake: aliceInitialStake, blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]});
        validators[2] = GenesisValidator({addr: jim, stake: jimInitialStake, blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]});
        stakeManager.initialize(address(token), blsAddr, address(epochManager), testDomain, validators);
    }
}

abstract contract Unstaked is Initialized {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(alice);
        stakeManager.unstake(newUnstakeAmount);

        vm.prank(SYSTEM);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        epochManager.commitEpoch(1, epoch);

        vm.prank(address(stakeManager));
        token.approve(alice, type(uint256).max);
    }
}

contract StakeManager_Initialize is Uninitialized {
    function testInititialize() public {
        GenesisValidator[] memory validators = new GenesisValidator[](3);
        validators[0] = GenesisValidator({addr: bob, stake: bobInitialStake, blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]});
        validators[1] = GenesisValidator({addr: alice, stake: aliceInitialStake, blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]});
        validators[2] = GenesisValidator({addr: jim, stake: jimInitialStake, blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]});
        stakeManager.initialize(address(token), blsAddr, address(epochManager), testDomain, validators);
    }
}

contract StakeManager_Stake is Initialized, StakeManager {
    function test_Stake(uint256 amount) public {
        vm.assume(amount <= newStakeAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeAdded(bob, amount);

        vm.prank(bob);
        stakeManager.stake(amount);
        uint256 totalStake = stakeManager.balanceOf(bob)+aliceInitialStake+jimInitialStake;
        assertEq(stakeManager.totalStake(), totalStake, "total stake mismatch");
        assertEq(stakeManager.stakeOf(bob), amount+bobInitialStake, "stake of mismatch");
        assertEq(token.balanceOf(address(stakeManager)), totalStake, "token balance mismatch");
    }
}

contract StakeManager_WithdrawStake is Unstaked, StakeManager {
    function test_WithdrawStake() public {
        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(alice, newUnstakeAmount);
        
        assertEq(stakeManager.withdrawable(alice), newUnstakeAmount, "withdrawable stake mismatch");
        assertEq(stakeManager.stakeOf(alice), aliceInitialStake-newUnstakeAmount, "expected stake missmatch");

        vm.prank(alice);
        stakeManager.withdraw();
    }
}
