// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {ValidatorSet, ValidatorInit, Epoch} from "contracts/child/validator/ValidatorSet.sol";
import {RewardPool, IRewardPool, Uptime} from "contracts/child/validator/RewardPool.sol";
import "contracts/interfaces/Errors.sol";

import {NetworkParams} from "contracts/child/NetworkParams.sol";

abstract contract Uninitialized is Test {
    address public constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    MockERC20 token;
    ValidatorSet validatorSet;
    RewardPool pool;
    address rewardWallet = makeAddr("rewardWallet");
    address alice = makeAddr("alice");
    uint256 epochSize = 64;

    NetworkParams networkParams;

    function setUp() public virtual {
        networkParams = new NetworkParams();
        networkParams.initialize(NetworkParams.InitParams(address(1), 1, 1, 1 ether, 1, 1, 1, 1, 1, 1, 1, 1));

        token = new MockERC20();
        validatorSet = new ValidatorSet();
        ValidatorInit[] memory init = new ValidatorInit[](2);
        init[0] = ValidatorInit({addr: address(this), stake: 300});
        init[1] = ValidatorInit({addr: alice, stake: 100});
        validatorSet.initialize(address(1), address(1), address(1), address(networkParams), init);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(1, epoch, epochSize);
        vm.roll(block.number + 1);
        pool = new RewardPool();
        token.mint(rewardWallet, 1000 ether);
        vm.prank(rewardWallet);
        token.approve(address(pool), type(uint256).max);
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        pool.initialize(address(token), rewardWallet, address(validatorSet), address(networkParams));
    }
}

abstract contract Distributed is Initialized {
    function setUp() public virtual override {
        super.setUp();
        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 64});
        uptime[1] = Uptime({validator: alice, signedBlocks: 64});
        vm.prank(SYSTEM);
        pool.distributeRewardFor(1, uptime, epochSize);
    }
}

contract RewardPool_Initialize is Uninitialized {
    function test_Initialize() public {
        pool.initialize(address(token), rewardWallet, address(validatorSet), address(networkParams));
        assertEq(address(pool.rewardToken()), address(token));
        assertEq(pool.rewardWallet(), rewardWallet);
        assertEq(address(pool.validatorSet()), address(validatorSet));
    }
}

contract RewardPool_Distribute is Initialized {
    event RewardDistributed(uint256 indexed epochId, uint256 totalReward);

    function test_RevertOnlySystem() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        pool.distributeRewardFor(1, new Uptime[](0), epochSize);
    }

    function test_RevertGenesisEpoch() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.expectRevert("EPOCH_NOT_COMMITTED");
        vm.prank(SYSTEM);
        pool.distributeRewardFor(0, uptime, epochSize);
    }

    function test_RevertFutureEpoch() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.expectRevert("EPOCH_NOT_COMMITTED");
        vm.prank(SYSTEM);
        pool.distributeRewardFor(2, uptime, epochSize);
    }

    function test_RevertSignedBlocksExceedsTotalBlocks() public {
        Uptime[] memory uptime = new Uptime[](1);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 65});
        vm.prank(SYSTEM);
        vm.expectRevert("SIGNED_BLOCKS_EXCEEDS_TOTAL");
        pool.distributeRewardFor(1, uptime, epochSize);
    }

    function test_DistributeRewards(uint256 epochReward) public {
        vm.assume(epochReward <= pool.rewardToken().balanceOf(rewardWallet));
        vm.mockCall(address(networkParams), abi.encodeCall(networkParams.epochReward, ()), abi.encode(epochReward));

        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 60});
        uptime[1] = Uptime({validator: alice, signedBlocks: 50});
        uint256 reward1 = (networkParams.epochReward() * 3 * 60) / (4 * 64);
        uint256 reward2 = (networkParams.epochReward() * 1 * 50) / (4 * 64);
        uint256 totalReward = reward1 + reward2;
        vm.prank(SYSTEM);
        vm.expectEmit(true, true, true, true);
        emit RewardDistributed(1, totalReward);
        pool.distributeRewardFor(1, uptime, epochSize);
        assertEq(pool.pendingRewards(address(this)), reward1);
        assertEq(pool.pendingRewards(alice), reward2);
        assertEq(pool.paidRewardPerEpoch(1), totalReward);
    }
}

contract RewardPool_DuplicateDistribution is Distributed {
    function test_RevertEpochAlreadyDistributed() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.startPrank(SYSTEM);
        vm.expectRevert("REWARD_ALREADY_DISTRIBUTED");
        pool.distributeRewardFor(1, uptime, epochSize);
    }
}

contract RewardPool_Withdrawal is Distributed {
    function test_SuccessfulWithdrawal() public {
        uint256 reward = pool.pendingRewards(address(this));
        pool.withdrawReward();
        assertEq(pool.pendingRewards(address(this)), 0);
        assertEq(token.balanceOf(address(this)), reward);
    }
}
