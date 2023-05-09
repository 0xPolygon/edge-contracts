// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {ValidatorSet, ValidatorInit, Epoch} from "contracts/child/validator/ValidatorSet.sol";
import {L2StateSender} from "contracts/child/L2StateSender.sol";
import "contracts/interfaces/Errors.sol";

abstract contract Uninitialized is Test {
    address internal constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    bytes32 internal constant STAKE_SIG = keccak256("STAKE");

    ValidatorSet validatorSet;
    L2StateSender stateSender;
    address stateReceiver = makeAddr("stateReceiver");
    address rootChainManager = makeAddr("rootChainManager");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 epochSize = 64;

    function setUp() public virtual {
        stateSender = new L2StateSender();
        validatorSet = new ValidatorSet();
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        ValidatorInit[] memory init = new ValidatorInit[](2);
        init[0] = ValidatorInit({addr: address(this), stake: 300});
        init[1] = ValidatorInit({addr: alice, stake: 100});
        validatorSet.initialize(address(stateSender), stateReceiver, rootChainManager, epochSize, init);
    }
}

abstract contract Committed is Initialized {
    function setUp() public virtual override {
        super.setUp();
        _beforeCommit();
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(1, epoch);
    }

    function _beforeCommit() internal virtual;
}

contract ValidatorSet_Initialize is Uninitialized {
    function test_Initialize() public {
        ValidatorInit[] memory init = new ValidatorInit[](2);
        init[0] = ValidatorInit({addr: address(this), stake: 300});
        init[1] = ValidatorInit({addr: alice, stake: 100});
        validatorSet.initialize(address(stateSender), stateReceiver, rootChainManager, epochSize, init);
        assertEq(validatorSet.EPOCH_SIZE(), epochSize);
        assertEq(validatorSet.balanceOf(address(this)), 300);
        assertEq(validatorSet.balanceOf(alice), 100);
        assertEq(validatorSet.totalSupply(), 400);
        assertEq(validatorSet.currentEpochId(), 1);
        assertEq(validatorSet.epochEndBlocks(0), 0);
    }
}

contract ValidatorSet_CommitEpoch is Initialized {
    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);

    function test_RevertOnlySystemCall() public {
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        validatorSet.commitEpoch(1, epoch);
    }

    function test_RevertInvalidEpochId(uint256 id) public {
        vm.assume(id != 1);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.expectRevert("UNEXPECTED_EPOCH_ID");
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(id, epoch);
    }

    function test_RevertNoBlocksCommitted(uint256 startBlock, uint256 endBlock) public {
        vm.assume(endBlock <= startBlock);
        Epoch memory epoch = Epoch({startBlock: startBlock, endBlock: endBlock, epochRoot: bytes32(0)});
        vm.expectRevert("NO_BLOCKS_COMMITTED");
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(1, epoch);
    }

    function test_RevertEpochSize(uint256 startBlock, uint256 endBlock) public {
        vm.assume(endBlock > startBlock && endBlock < type(uint256).max);
        vm.assume((endBlock - startBlock + 1) % epochSize != 0);
        Epoch memory epoch = Epoch({startBlock: startBlock, endBlock: endBlock, epochRoot: bytes32(0)});
        vm.expectRevert("EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(1, epoch);
    }

    function test_RevertInvalidStartBlock() public {
        Epoch memory epoch = Epoch({startBlock: 0, endBlock: 63, epochRoot: bytes32(0)});
        vm.expectRevert("INVALID_START_BLOCK");
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(1, epoch);
    }

    function test_CommitEpoch() public {
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        vm.expectEmit(true, true, true, true);
        emit NewEpoch(1, 1, 64, bytes32(0));
        validatorSet.commitEpoch(1, epoch);
        assertEq(validatorSet.currentEpochId(), 2);
        assertEq(validatorSet.epochEndBlocks(1), 64);
        assertEq(validatorSet.totalBlocks(1), 64);
    }
}

contract ValidatorSet_TransferForbidden is Initialized {
    function test_RevertTransfer() public {
        vm.expectRevert("TRANSFER_FORBIDDEN");
        validatorSet.transfer(bob, 100);
    }
}

contract ValidatorSet_Stake is Initialized {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function test_RevertInvalidMsgSender() public {
        vm.expectRevert("INVALID_SENDER");
        validatorSet.onStateReceive(1, rootChainManager, "");
    }

    function test_RevertInvalidSender() public {
        vm.expectRevert("INVALID_SENDER");
        vm.prank(stateReceiver);
        validatorSet.onStateReceive(1, alice, "");
    }

    function test_Stake(uint256 amount) public {
        vm.assume(amount < type(uint256).max - validatorSet.balanceOf(alice));
        bytes memory callData = abi.encode(STAKE_SIG, alice, amount);
        vm.prank(stateReceiver);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, amount);
        validatorSet.onStateReceive(1, rootChainManager, callData);
    }
}

contract ValidatorSet_Unstake is Initialized {
    event WithdrawalRegistered(address indexed account, uint256 amount);

    function test_Unstake(uint256 amount) public {
        uint256 balance = validatorSet.balanceOf(address(this));
        vm.assume(amount < balance && amount != 0);
        vm.expectEmit(true, true, true, true);
        emit WithdrawalRegistered(address(this), amount);
        validatorSet.unstake(amount);
        assertEq(validatorSet.balanceOf(address(this)), balance - amount);
        assertEq(validatorSet.pendingWithdrawals(address(this)), amount);
        assertEq(validatorSet.withdrawable(address(this)), 0);
    }
}

contract ValidatorSet_StakeChanges is Committed {
    function _beforeCommit() internal override {
        bytes memory callData = abi.encode(STAKE_SIG, alice, 100);
        vm.prank(stateReceiver);
        validatorSet.onStateReceive(1, rootChainManager, callData);
        validatorSet.unstake(50);
    }

    function test_StakeChanges() public {
        assertEq(validatorSet.balanceOf(address(this)), 250);
        assertEq(validatorSet.balanceOf(alice), 200);
        assertEq(validatorSet.balanceOfAt(address(this), 1), 300);
        assertEq(validatorSet.balanceOfAt(alice, 1), 100);
        assertEq(validatorSet.totalSupply(), 450);
        assertEq(validatorSet.totalSupplyAt(1), 400);
    }
}

contract ValidatorSet_WithdrawStake is Committed {
    event Withdrawal(address indexed account, uint256 amount);
    uint256 amount = 100;
    event L2StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    bytes32 private constant UNSTAKE_SIG = keccak256("UNSTAKE");

    function _beforeCommit() internal override {
        validatorSet.unstake(amount);
    }

    function test_WithdrawStake() public {
        uint256 withdrawable = validatorSet.withdrawable(address(this));
        assertEq(withdrawable, amount);
        assertEq(validatorSet.pendingWithdrawals(address(this)), 0);
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(address(this), amount);
        vm.expectEmit(true, true, true, true);
        emit L2StateSynced(1, address(validatorSet), rootChainManager, abi.encode(UNSTAKE_SIG, address(this), amount));
        validatorSet.withdraw();
        assertEq(validatorSet.withdrawable(address(this)), 0);
    }
}
