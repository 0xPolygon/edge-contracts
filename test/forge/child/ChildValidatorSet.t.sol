// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChildValidatorSet} from "contracts/child/ChildValidatorSet.sol";
import {System} from "contracts/child/ChildValidatorSet.sol";
import {BLS} from "contracts/common/BLS.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/IValidator.sol";
import "contracts/interfaces/IChildValidatorSet.sol";

import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus, System {
    ChildValidatorSet childValidatorSet;
    BLS bls;

    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;
    address public admin;
    address public alice;
    address public bob;
    address[] validatorAddresses;
    uint256[4][] validatorPubkeys;
    uint256[] validatorStakes;
    uint256[2] messagePoint;
    address governance;
    uint256[2] signature;
    uint256[4] pubkey;
    Epoch epoch;
    Uptime uptime;
    uint256 public id;

    function setUp() public virtual {
        epochReward = 0.0000001 ether;
        minStake = 10000;
        minDelegation = 10000;

        bls = new BLS();
        childValidatorSet = new ChildValidatorSet();

        admin = makeAddr("admin");
        governance = admin;
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        validatorAddresses.push(admin);
        validatorPubkeys.push([0, 0, 0, 0]);
        validatorStakes.push(minStake * 2);
        messagePoint[0] = 0;
        messagePoint[1] = 0;
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(SYSTEM);

        string[] memory cmd = new string[](3);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/child/generateMsg.ts";
        bytes memory out = vm.ffi(cmd);

        (messagePoint, signature, pubkey) = abi.decode(out, (uint256[2], uint256[2], uint256[4]));

        childValidatorSet.initialize(
            epochReward,
            minStake,
            minDelegation,
            validatorAddresses,
            validatorPubkeys,
            validatorStakes,
            bls,
            messagePoint,
            governance
        );
    }
}

abstract contract Whitelisted is Initialized {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(governance);
        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = admin;
        whitelistAddresses[1] = alice;

        childValidatorSet.addToWhitelist(whitelistAddresses);
    }
}

abstract contract Registered is Whitelisted {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(alice);
        childValidatorSet.register(signature, pubkey);
    }
}

abstract contract Staked is Registered {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(alice);
        vm.deal(alice, 100 ether);
        childValidatorSet.stake{value: minStake * 2}();
    }
}

abstract contract QueueProcessed is Staked {
    function setUp() public virtual override {
        super.setUp();

        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 1;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }
}

abstract contract UnstakedPartially is QueueProcessed {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(alice);
        childValidatorSet.unstake(minStake);
    }
}

abstract contract UnstakedCompletely is UnstakedPartially {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(alice);
        childValidatorSet.unstake(minStake);
    }
}

abstract contract QueueProcessedAfterUnstake is UnstakedCompletely {
    function setUp() public virtual override {
        super.setUp();

        id = 2;
        epoch = Epoch({startBlock: 65, endBlock: 128, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));

        uptime.epochId = 2;
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }
}

abstract contract Withdrawn is QueueProcessedAfterUnstake {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(alice);
        childValidatorSet.withdraw(alice);

        //Whitelist Alice again
        vm.prank(governance);
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        childValidatorSet.addToWhitelist(whitelistAddresses);

        //Register Alice again
        vm.prank(alice);
        childValidatorSet.register(signature, pubkey);

        //Stake Again
        vm.prank(alice);
        vm.deal(alice, 100 ether);
        childValidatorSet.stake{value: minStake * 2}();
    }
}

abstract contract FirstDelegated is Withdrawn {
    function setUp() public virtual override {
        super.setUp();

        uint256 delegateAmount = minDelegation + 1;
        bool restake = false;

        vm.prank(bob);
        vm.deal(bob, 100 ether);

        childValidatorSet.delegate{value: delegateAmount}(alice, restake);
    }
}

abstract contract SecondDelegated is FirstDelegated {
    function setUp() public virtual override {
        super.setUp();

        uint256 delegateAmount = minDelegation + 1;
        bool restake = false;

        vm.prank(bob);
        vm.deal(bob, 100 ether);

        childValidatorSet.delegate{value: delegateAmount}(alice, restake);
    }
}

abstract contract ThirdDelegated is SecondDelegated {
    function setUp() public virtual override {
        super.setUp();

        uint256 delegateAmount = minDelegation + 1;
        bool restake = true;

        vm.prank(bob);
        vm.deal(bob, 100 ether);

        childValidatorSet.delegate{value: delegateAmount}(alice, restake);
    }
}

contract ChildValidatorSetTest_Unitialized is Uninitialized {
    function testConstructor() public {
        assertEq(childValidatorSet.currentEpochId(), 0);
    }

    function testCannotInitialize_Unauthorized() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));

        childValidatorSet.initialize(
            epochReward,
            minStake,
            minDelegation,
            validatorAddresses,
            validatorPubkeys,
            validatorStakes,
            bls,
            messagePoint,
            governance
        );
    }

    function testInitialize() public {
        vm.startPrank(SYSTEM);

        assertEq(childValidatorSet.totalActiveStake(), 0);

        childValidatorSet.initialize(
            epochReward,
            minStake,
            minDelegation,
            validatorAddresses,
            validatorPubkeys,
            validatorStakes,
            bls,
            messagePoint,
            governance
        );

        assertEq(childValidatorSet.epochReward(), epochReward);
        assertEq(childValidatorSet.minStake(), minStake);
        assertEq(childValidatorSet.minDelegation(), minDelegation);
        assertEq(childValidatorSet.currentEpochId(), 1);
        assertEq(childValidatorSet.owner(), governance);

        assertEq(childValidatorSet.currentEpochId(), 1);
        assertEq(childValidatorSet.whitelist(validatorAddresses[0]), true);

        Validator memory validator = childValidatorSet.getValidator(validatorAddresses[0]);
        Validator memory validatorExpected = Validator(validatorPubkeys[0], minStake * 2, minStake * 2, 0, 0, true);

        address blsAddr = address(childValidatorSet.bls());
        assertEq(validator, validatorExpected, "validator check");
        assertEq(blsAddr, address(bls));
        assertEq(childValidatorSet.message(0), messagePoint[0]);
        assertEq(childValidatorSet.message(1), messagePoint[1]);
        assertEq(childValidatorSet.totalActiveStake(), minStake * 2);
    }
}

contract ChildValidatorSetTest_CommitEpoch_Whitelist is Initialized {
    function testCannotInitialize_Reinitialization() public {
        vm.expectRevert("Initializable: contract is already initialized");

        vm.startPrank(SYSTEM);
        childValidatorSet.initialize(
            epochReward,
            minStake,
            minDelegation,
            validatorAddresses,
            validatorPubkeys,
            validatorStakes,
            bls,
            messagePoint,
            governance
        );
    }

    function testCannotCommitEpoch_Unauthorized() public {
        id = 0;
        epoch = Epoch({startBlock: 0, endBlock: 0, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptime.epochId = 0;
        uptime.totalBlocks = 0;

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCannotCommitEpoch_UnexpectedId() public {
        id = 0;
        epoch = Epoch({startBlock: 0, endBlock: 0, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptime.epochId = 0;
        uptime.totalBlocks = 0;

        vm.startPrank(SYSTEM);

        vm.expectRevert("UNEXPECTED_EPOCH_ID");
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCannotCommitEpoch_NoBlocksCommited() public {
        id = 1;
        epoch = Epoch({startBlock: 0, endBlock: 0, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptime.epochId = 0;
        uptime.totalBlocks = 0;

        vm.startPrank(SYSTEM);

        vm.expectRevert("NO_BLOCKS_COMMITTED");
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCannotCommitEpoch_IncompleteSprint() public {
        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 63, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptime.epochId = 0;
        uptime.totalBlocks = 0;

        vm.startPrank(SYSTEM);

        vm.expectRevert("EPOCH_MUST_BE_DIVISIBLE_BY_64");
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCannotCommitEpoch_NoCommittedEpoch() public {
        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptime.epochId = 0;
        uptime.totalBlocks = 0;

        vm.startPrank(SYSTEM);

        vm.expectRevert("EPOCH_NOT_COMMITTED");
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCannotCommitEpoch_InvalidLength() public {
        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 0;

        vm.startPrank(SYSTEM);

        vm.expectRevert("INVALID_LENGTH");
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCommitEpoch() public {
        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 1;

        vm.startPrank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        (uint256 startBlock, uint256 endBlock, bytes32 epochRoot) = childValidatorSet.epochs(1);
        assertEq(startBlock, epoch.startBlock);
        assertEq(endBlock, epoch.endBlock);
        assertEq(epochRoot, epoch.epochRoot);
    }

    function testCannotCommitEpoch_OldBlock() public {
        id = 1;
        epoch = Epoch({startBlock: 0, endBlock: 63, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 0;

        vm.startPrank(SYSTEM);

        vm.expectRevert("INVALID_START_BLOCK");
        childValidatorSet.commitEpoch(id, epoch, uptime);
    }

    function testCurrentValidatorSet() public {
        address[] memory currentValidatorSet = childValidatorSet.getCurrentValidatorSet();
        assertEq(currentValidatorSet[0], admin);
    }

    function testGetEpochByBlock() public {
        Epoch memory storedEpoch = childValidatorSet.getEpochByBlock(64);
        assertEq(storedEpoch.startBlock, epoch.startBlock);
        assertEq(storedEpoch.endBlock, epoch.endBlock);
        assertEq(storedEpoch.epochRoot, epoch.epochRoot);
    }

    function testGetNonExistentEpochByBlock() public {
        Epoch memory storedEpoch = childValidatorSet.getEpochByBlock(65);
        assertEq(storedEpoch.startBlock, 0);
        assertEq(storedEpoch.endBlock, 0);
        assertEq(storedEpoch.epochRoot, 0);
    }

    function testCommitEpochWithoutStaking() public {
        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 1000000000000}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 1;

        vm.startPrank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        (uint256 startBlock, uint256 endBlock, bytes32 epochRoot) = childValidatorSet.epochs(1);
        assertEq(startBlock, epoch.startBlock);
        assertEq(endBlock, epoch.endBlock);
        assertEq(epochRoot, epoch.epochRoot);
    }

    function testCannotAddWhitelist() public {
        vm.startPrank(alice);

        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "OWNER"));
        childValidatorSet.addToWhitelist(whitelistAddresses);
    }

    function testCannotRemoveWhitelist() public {
        vm.startPrank(alice);

        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "OWNER"));
        childValidatorSet.removeFromWhitelist(whitelistAddresses);
    }

    function testAddWhitelist() public {
        vm.startPrank(governance);
        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = admin;
        whitelistAddresses[1] = alice;

        childValidatorSet.addToWhitelist(whitelistAddresses);
        assertEq(childValidatorSet.whitelist(admin), true);
        assertEq(childValidatorSet.whitelist(alice), true);
    }

    function testRemoveWhitelist() public {
        assertEq(childValidatorSet.whitelist(admin), true);
        vm.startPrank(governance);
        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = admin;

        childValidatorSet.removeFromWhitelist(whitelistAddresses);
        assertEq(childValidatorSet.whitelist(admin), false);
    }
}

contract ChildValidatorSetTest_Register is Whitelisted {
    event NewValidator(address indexed validator, uint256[4] blsKey);

    function testCannotRegister_NotWhitelisted() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "WHITELIST"));
        childValidatorSet.register(signature, pubkey);
    }

    function testCannotRegister_InvalidSignature() public {
        pubkey[0] = pubkey[0] + 1;
        vm.startPrank(admin);
        vm.expectRevert("INVALID_SIGNATURE");
        childValidatorSet.register(signature, pubkey);
    }

    function testRegister() public {
        vm.startPrank(alice);
        vm.expectEmit(true, false, false, true);
        emit NewValidator(alice, pubkey);
        childValidatorSet.register(signature, pubkey);

        assertEq(childValidatorSet.whitelist(alice), false);
        Validator memory validator = childValidatorSet.getValidator(alice);
        assertEq(keccak256(abi.encode(validator.blsKey)), keccak256(abi.encode(pubkey)));
        assertEq(validator.stake, 0);
        assertEq(validator.totalStake, 0);
        assertEq(validator.commission, 0);
        assertEq(validator.withdrawableRewards, 0);
        assertEq(validator.active, true);
    }
}

contract ChildValidatorSetTest_Stake is Registered {
    function testCannotStake_NotWhitelistedvalidator() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "VALIDATOR"));
        childValidatorSet.stake{value: minStake}();
    }

    function testCannotStake_StakeTooLow() public {
        vm.startPrank(alice);
        vm.deal(alice, 100 ether);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "stake", "STAKE_TOO_LOW"));
        childValidatorSet.stake{value: minStake - 1}();
    }

    function testStake() public {
        vm.startPrank(alice);
        vm.deal(alice, 100 ether);
        childValidatorSet.stake{value: minStake * 2}();
        assertEq(childValidatorSet.totalActiveStake(), minStake * 2);

        //Get 0 sortedValidators
        address[] memory validatorAddresses = childValidatorSet.sortedValidators(0);
        assertEq(validatorAddresses.length, 0);
    }
}

contract ChildValidatorSetTest_ProcessQueue is Staked {
    function testQueueProcess() public {
        Validator memory validator = childValidatorSet.getValidator(alice);
        assertEq(validator.stake, 0);

        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 1;

        vm.startPrank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        validator = childValidatorSet.getValidator(alice);
        assertEq(validator.stake, minStake * 2);

        //Get 2 sortedValidators
        address[] memory validatorAddresses = childValidatorSet.sortedValidators(3);
        assertEq(keccak256(abi.encodePacked(validatorAddresses)), keccak256(abi.encodePacked([alice, admin])));
    }
}

contract ChildValidatorSetTest_UnstakePartially is QueueProcessed {
    function testCannotUnstake_InsufficientBalance() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "unstake", "INSUFFICIENT_BALANCE"));
        childValidatorSet.unstake(1);
    }

    function testCannotUnstake_IntOverflow() public {
        vm.expectRevert(stdError.assertionError);
        // vm.expectRevert(stdError.arithmeticError);
        // vm.expectRevert();
        childValidatorSet.unstake(2**256 - 1);
    }

    function testCannotUnstake_UnstakeMoreThanStake() public {
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "unstake", "INSUFFICIENT_BALANCE"));
        childValidatorSet.unstake(minStake * 2 + 1);
    }

    function testCannotUnstake_StakeTooLow() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "unstake", "STAKE_TOO_LOW"));
        childValidatorSet.unstake(minStake + 1);
    }

    function testUnstakePartially() public {
        vm.startPrank(alice);
        childValidatorSet.unstake(minStake);
    }
}

contract ChildValidatorSetTest_UnstakeCompletely is UnstakedPartially {
    function testCannotUnstake_InsufficientBalance() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "unstake", "INSUFFICIENT_BALANCE"));
        childValidatorSet.unstake(minStake + 1);
    }

    function testCannotUnstake_StakeTooLow() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "unstake", "STAKE_TOO_LOW"));
        childValidatorSet.unstake(1);
    }

    function testUnstakeCompletely() public {
        vm.startPrank(alice);
        childValidatorSet.unstake(minStake);
    }
}

contract ChildValidatorSetTest_ProcessQueueAfterStake is UnstakedCompletely {
    function testCheckWithdrawalQueue() public {
        assertEq(childValidatorSet.pendingWithdrawals(alice), minStake * 2);
        assertEq(childValidatorSet.withdrawable(alice), 0);
    }

    function testProcessQueue() public {
        Validator memory validator = childValidatorSet.getValidator(alice);
        assertEq(validator.stake, minStake * 2);

        id = 2;
        epoch = Epoch({startBlock: 65, endBlock: 128, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        validator = childValidatorSet.getValidator(alice);
        assertEq(validator.stake, 0);
        assertEq(childValidatorSet.pendingWithdrawals(alice), 0);
        assertEq(childValidatorSet.withdrawable(alice), minStake * 2);
    }
}

contract ChildValidatorSetTest_Withdraw is QueueProcessedAfterUnstake {
    event Withdrawal(address indexed account, address indexed to, uint256 amount);

    function testCannotWithdraw_Failed() public {
        vm.deal(address(childValidatorSet), 0);
        vm.startPrank(alice);
        vm.expectRevert("WITHDRAWAL_FAILED");
        childValidatorSet.withdraw(admin);
    }

    function testWithdraw() public {
        vm.startPrank(alice);

        vm.expectEmit(true, true, false, true);
        emit Withdrawal(alice, alice, minStake * 2);

        childValidatorSet.withdraw(alice);

        assertEq(childValidatorSet.pendingWithdrawals(alice), 0);
        assertEq(childValidatorSet.withdrawable(alice), 0);
    }
}

contract ChildValidatorSetTest_FirstDelegate is Withdrawn {
    event Withdrawal(address indexed account, address indexed to, uint256 amount);
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);

    function testCannotDelegate_InvalidValidator() public {
        bool restake = false;
        vm.startPrank(bob);
        vm.deal(bob, 100 ether);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "INVALID_VALIDATOR"));

        childValidatorSet.delegate{value: minDelegation}(bob, restake);
    }

    function testCannotDelegate_DelegationTooLow() public {
        bool restake = false;
        vm.startPrank(alice);
        vm.deal(alice, 100 ether);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "delegate", "DELEGATION_TOO_LOW"));

        childValidatorSet.delegate{value: 100}(alice, restake);
    }

    function testFirstDelegate() public {
        uint256 delegateAmount = minDelegation + 1;
        bool restake = false;

        vm.startPrank(bob);
        vm.deal(bob, 100 ether);

        vm.expectEmit(true, true, false, true);
        emit Delegated(bob, alice, delegateAmount);
        childValidatorSet.delegate{value: delegateAmount}(alice, restake);
    }
}

contract ChildValidatorSetTest_SecondDelegate is FirstDelegated {
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);

    function testSecondDelegateWithoutRestake() public {
        uint256 delegateAmount = minDelegation + 1;
        bool restake = false;

        vm.startPrank(bob);
        vm.deal(bob, 100 ether);

        vm.expectEmit(true, true, false, true);
        emit Delegated(bob, alice, delegateAmount);
        childValidatorSet.delegate{value: delegateAmount}(alice, restake);
    }
}

contract ChildValidatorSetTest_ThirdDelegate is SecondDelegated {
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);

    function testThirdDelegateWithRestake() public {
        uint256 delegateAmount = minDelegation + 1;
        bool restake = true;

        vm.startPrank(bob);
        vm.deal(bob, 100 ether);

        vm.expectEmit(true, true, false, true);
        emit Delegated(bob, alice, delegateAmount);
        childValidatorSet.delegate{value: delegateAmount}(alice, restake);
    }
}

contract ChildValidatorSetTest_Claim is ThirdDelegated {
    event ValidatorRewardClaimed(address indexed validator, uint256 amount);
    event WithdrawalRegistered(address indexed account, uint256 amount);

    function testClaimValidatorReward() public {
        uint256 reward = childValidatorSet.getValidatorReward(admin);

        vm.expectEmit(true, false, false, true);
        emit WithdrawalRegistered(admin, reward);

        vm.expectEmit(true, false, false, true);
        emit ValidatorRewardClaimed(admin, reward);

        vm.startPrank(admin);
        childValidatorSet.claimValidatorReward();
    }
}
