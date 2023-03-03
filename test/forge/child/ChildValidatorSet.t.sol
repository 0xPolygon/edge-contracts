// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@utils/Test.sol";

import {ChildValidatorSet} from "contracts/child/ChildValidatorSet.sol";
import {System} from "contracts/child/ChildValidatorSet.sol";
import {BLS} from "contracts/common/BLS.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/IValidator.sol";
import "contracts/interfaces/modules/ICVSStorage.sol";
import "contracts/interfaces/IValidator.sol";
import "contracts/interfaces/IChildValidatorSetBase.sol";

abstract contract Uninitialized is Test, System {
    ChildValidatorSet childValidatorSet;
    BLS bls;

    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;
    address public admin;
    address public alice;
    address public bob;
    IChildValidatorSetBase.ValidatorInit[] validators;
    address governance;
    Epoch epoch;
    Uptime uptime;
    uint256 public id;
    uint256 constant MAX_COMMISSION = 100;
    uint256 blockNumber;
    uint256 pbftRound;

    bytes public constant alwaysTrueBytecode = hex"600160005260206000F3";
    bytes public constant alwaysFalseBytecode = hex"60206000F3";

    IChildValidatorSetBase.DoubleSignerSlashingInput[] public inputs;

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
    }

    function getSignatureAndPubKey(address addr) public returns (uint256[2] memory, uint256[4] memory) {
        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/child/generateMsg.ts";
        cmd[3] = toHexString(addr);
        bytes memory out = vm.ffi(cmd);

        (uint256[2] memory signature, uint256[4] memory pubkey) = abi.decode(out, (uint256[2], uint256[4]));

        return (signature, pubkey);
    }

    function toHexString(address addr) public pure returns (string memory) {
        bytes memory buffer = abi.encodePacked(addr);

        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(SYSTEM);

        IChildValidatorSetBase.InitStruct memory init = IChildValidatorSetBase.InitStruct(
            epochReward,
            minStake,
            minDelegation,
            64
        );

        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(admin);

        validators.push(
            IChildValidatorSetBase.ValidatorInit({
                addr: admin,
                pubkey: pubkey,
                signature: signature,
                stake: minStake * 2
            })
        );

        childValidatorSet.initialize(init, validators, bls, governance);
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
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(alice);
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

        uptime.epochId = childValidatorSet.currentEpochId();
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
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(alice);
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

abstract contract Claimed is ThirdDelegated {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(admin);
        childValidatorSet.claimValidatorReward();

        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData[0] = uptimeData[1];
        delete uptimeData[1];
        uptimeData.pop();

        id = 3;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        id = 4;
        epoch = Epoch({startBlock: 193, endBlock: 256, epochRoot: keccak256(abi.encodePacked(block.number))});

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        vm.prank(bob);
        childValidatorSet.claimDelegatorReward(alice, true);

        vm.prank(bob);
        childValidatorSet.claimDelegatorReward(alice, false);
    }
}

abstract contract UndelegatedState is Claimed {
    function setUp() public virtual override {
        super.setUp();

        uint256 delegatedAmount = childValidatorSet.delegationOf(alice, bob);

        vm.prank(bob);
        childValidatorSet.undelegate(alice, delegatedAmount);
    }
}

contract ChildValidatorSetTest_Initialize is Uninitialized {
    function testConstructor() public {
        assertEq(childValidatorSet.currentEpochId(), 0);
    }

    function testCannotInitialize_Unauthorized() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        IChildValidatorSetBase.InitStruct memory init = IChildValidatorSetBase.InitStruct(
            epochReward,
            minStake,
            minDelegation,
            64
        );

        childValidatorSet.initialize(init, validators, bls, governance);
    }

    function testInitialize() public {
        vm.startPrank(SYSTEM);

        assertEq(childValidatorSet.totalActiveStake(), 0);

        IChildValidatorSetBase.InitStruct memory init = IChildValidatorSetBase.InitStruct(
            epochReward,
            minStake,
            minDelegation,
            64
        );

        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(admin);

        validators.push(
            IChildValidatorSetBase.ValidatorInit({
                addr: admin,
                pubkey: pubkey,
                signature: signature,
                stake: minStake * 2
            })
        );

        childValidatorSet.initialize(init, validators, bls, governance);

        assertEq(childValidatorSet.epochReward(), epochReward);
        assertEq(childValidatorSet.minStake(), minStake);
        assertEq(childValidatorSet.minDelegation(), minDelegation);
        assertEq(childValidatorSet.currentEpochId(), 1);
        assertEq(childValidatorSet.owner(), governance);

        assertEq(childValidatorSet.currentEpochId(), 1);
        address validatorAddr = validators[0].addr;
        assert(validatorAddr != address(0));
        assertEq(childValidatorSet.whitelist(validatorAddr), false);

        (
            uint256[4] memory blsKey,
            uint256 stake,
            ,
            uint256 commission,
            uint256 withdrawableRewards,
            bool active
        ) = childValidatorSet.getValidator(validatorAddr);
        Validator memory validator = Validator(blsKey, stake, commission, withdrawableRewards, active);
        Validator memory validatorExpected = Validator(validators[0].pubkey, minStake * 2, 0, 0, true);

        address blsAddr = address(childValidatorSet.bls());
        assertEq(validator, validatorExpected, "validator check");
        assertEq(blsAddr, address(bls));
        assertEq(childValidatorSet.totalActiveStake(), minStake * 2);
    }
}

contract ChildValidatorSetTest_CommitEpoch_Whitelist is Initialized {
    function testCannotInitialize_Reinitialization() public {
        vm.expectRevert("Initializable: contract is already initialized");

        vm.startPrank(SYSTEM);
        IChildValidatorSetBase.InitStruct memory init = IChildValidatorSetBase.InitStruct(
            epochReward,
            minStake,
            minDelegation,
            64
        );

        childValidatorSet.initialize(init, validators, bls, governance);
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

        vm.expectRevert("EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
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

        vm.expectRevert("Ownable: caller is not the owner");
        childValidatorSet.addToWhitelist(whitelistAddresses);
    }

    function testCannotRemoveWhitelist() public {
        vm.startPrank(alice);

        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        vm.expectRevert("Ownable: caller is not the owner");
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
        vm.startPrank(governance);
        address[] memory whitelistAddress = new address[](1);
        whitelistAddress[0] = admin;
        childValidatorSet.addToWhitelist(whitelistAddress);
        assertEq(childValidatorSet.whitelist(admin), true);
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
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(bob);
        childValidatorSet.register(signature, pubkey);
    }

    function testCannotRegister_InvalidSignature() public {
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(alice);
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector, admin));
        childValidatorSet.register(signature, pubkey);
    }

    function testRegister() public {
        vm.startPrank(alice);
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(alice);
        vm.expectEmit(true, false, false, true);
        emit NewValidator(alice, pubkey);
        childValidatorSet.register(signature, pubkey);

        assertEq(childValidatorSet.whitelist(alice), false);
        (
            uint256[4] memory blsKey,
            uint256 stake,
            ,
            uint256 commission,
            uint256 withdrawableRewards,
            bool active
        ) = childValidatorSet.getValidator(alice);
        assertEq(keccak256(abi.encode(blsKey)), keccak256(abi.encode(pubkey)));
        assertEq(stake, 0);
        assertEq(commission, 0);
        assertEq(withdrawableRewards, 0);
        assertEq(active, true);
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
        (, uint256 stake, , , , ) = childValidatorSet.getValidator(alice);
        assertEq(stake, 0);

        id = 1;
        epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 1;

        vm.startPrank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        (, stake, , , , ) = childValidatorSet.getValidator(alice);
        assertEq(stake, minStake * 2);

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
        childValidatorSet.unstake(2 ** 256 - 1);
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
        (, uint256 stake, , , , ) = childValidatorSet.getValidator(alice);
        assertEq(stake, minStake * 2);

        id = 2;
        epoch = Epoch({startBlock: 65, endBlock: 128, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        (, stake, , , , ) = childValidatorSet.getValidator(alice);
        assertEq(stake, 0);
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
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);
    event DelegatorRewardClaimed(
        address indexed delegator,
        address indexed validator,
        bool indexed restake,
        uint256 amount
    );

    function testClaimValidatorReward() public {
        uint256 reward = childValidatorSet.getValidatorReward(admin);

        vm.expectEmit(true, false, false, true);
        emit WithdrawalRegistered(admin, reward);

        vm.expectEmit(true, false, false, true);
        emit ValidatorRewardClaimed(admin, reward);

        vm.startPrank(admin);
        childValidatorSet.claimValidatorReward();
    }

    function testClaimDelegatorRewardWithRestake() public {
        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData[0] = uptimeData[1];
        delete uptimeData[1];
        uptimeData.pop();

        id = 3;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        id = 4;
        epoch = Epoch({startBlock: 193, endBlock: 256, epochRoot: keccak256(abi.encodePacked(block.number))});

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        uint256 reward = childValidatorSet.getDelegatorReward(alice, bob);
        bool restake = true;

        vm.prank(bob);

        vm.expectEmit(true, true, false, true);
        emit Delegated(bob, alice, reward);

        vm.expectEmit(true, true, true, true);
        emit DelegatorRewardClaimed(bob, alice, true, reward);

        childValidatorSet.claimDelegatorReward(alice, restake);
    }

    function testClaimDelegatorRewardWithoutRestake() public {
        UptimeData[] storage uptimeData = uptime.uptimeData;
        uptimeData[0] = uptimeData[1];
        delete uptimeData[1];
        uptimeData.pop();

        id = 3;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        id = 4;
        epoch = Epoch({startBlock: 193, endBlock: 256, epochRoot: keccak256(abi.encodePacked(block.number))});

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        vm.prank(SYSTEM);
        childValidatorSet.commitEpoch(id, epoch, uptime);

        uint256 reward = childValidatorSet.getDelegatorReward(alice, bob);
        bool restake = false;

        vm.prank(bob);

        vm.expectEmit(true, false, false, true);
        emit WithdrawalRegistered(bob, reward);

        vm.expectEmit(true, true, true, true);
        emit DelegatorRewardClaimed(bob, alice, false, reward);

        childValidatorSet.claimDelegatorReward(alice, restake);
    }
}

contract ChildValidatorSetTest_CommitEpochWithDoubleSignerSlashing is Claimed {
    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);
    uint256 public constant DOUBLE_SIGNING_SLASHING_PERCENT = 10;

    function testCannotCommitEpochWithDoubleSignerSlashing_InvalidLength() public {
        id = 3;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 0;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x",
                signature: ""
            })
        );

        inputs[0].signature = abi.encode(
            block.chainid,
            blockNumber,
            inputs[0].blockHash,
            pbftRound,
            inputs[0].epochId,
            inputs[0].eventRoot,
            inputs[0].currentValidatorSetHash,
            inputs[0].nextValidatorSetHash
        );

        vm.expectRevert("INVALID_LENGTH");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCannotCommitEpochWithDoubleSignerSlashing_BlockHashNotUnique() public {
        id = 3;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));
        uptimeData.push(UptimeData({validator: admin, signedBlocks: 0}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 0;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }

        vm.expectRevert("BLOCKHASH_NOT_UNIQUE");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCannotCommitEpochWithDoubleSignerSlashing_SignatureVerificationFailed() public {
        id = 3;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: "0x",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }
        // inputs[1].signature = inputs[0].signature;
        vm.etch(0x0000000000000000000000000000000000002030, alwaysFalseBytecode);

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCannotCommitEpochWithDoubleSignerSlashing_UndexpectedEpochId() public {
        id = 2;
        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }

        vm.etch(0x0000000000000000000000000000000000002030, alwaysTrueBytecode);

        vm.expectRevert("UNEXPECTED_EPOCH_ID");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            0, //For unexpected id
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCannotCommitEpochWithDoubleSignerSlashing_NoBlocksCommited() public {
        id = 5;
        epoch = Epoch({startBlock: 129, endBlock: 129, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));
        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }
        vm.etch(0x0000000000000000000000000000000000002030, alwaysTrueBytecode);

        vm.expectRevert("NO_BLOCKS_COMMITTED");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCannotCommitEpochWithDoubleSignerSlashing_InvalidLengthByUptimeData() public {
        id = 5;
        epoch = Epoch({startBlock: 257, endBlock: 320, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));
        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));
        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }

        vm.etch(0x0000000000000000000000000000000000002030, alwaysTrueBytecode);

        vm.expectRevert("INVALID_LENGTH");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCommitEpochWithDoubleSignerSlashing() public {
        id = 5;
        epoch = Epoch({startBlock: 257, endBlock: 320, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }

        vm.etch(0x0000000000000000000000000000000000002030, alwaysTrueBytecode);

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCannotCommitEpochWithDoubleSignerSlashing_InvalidStartBlock() public {
        id = 5;
        epoch = Epoch({startBlock: 255, endBlock: 318, epochRoot: keccak256(abi.encodePacked(block.number))});

        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));

        uptime.epochId = childValidatorSet.currentEpochId();
        uptime.totalBlocks = 2;

        blockNumber = 0;
        pbftRound = 0;

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: "0x000000000000000000000000",
                signature: ""
            })
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }

        vm.etch(0x0000000000000000000000000000000000002030, alwaysTrueBytecode);

        vm.expectRevert("INVALID_START_BLOCK");

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );
    }

    function testCommitEpochWithDoubleSignerSlashing_FuzzyBitmapFuzzyValidators_SignSameEpochPbftRoundKey() public {
        UptimeData[] storage uptimeData = uptime.uptimeData;

        uptimeData.push(UptimeData({validator: alice, signedBlocks: 1}));
        uptime.totalBlocks = 2;

        uint256 newValidatorsCount = (block.timestamp % 4) + 6;
        uint256 i;

        bytes memory chars = new bytes(16);
        chars = "0123456789abcdef";
        id = 5;
        {
            bytes memory addrName = new bytes(1);
            for (i = 0; i < newValidatorsCount; i++) {
                addrName[0] = chars[i];
                address addr = makeAddr(string(addrName));
                vm.deal(addr, 100 ether);

                address[] memory whitelistAddresses = new address[](1);
                whitelistAddresses[0] = addr;
                vm.stopPrank();
                vm.startPrank(governance);
                childValidatorSet.addToWhitelist(whitelistAddresses);

                vm.stopPrank();
                vm.startPrank(addr);
                (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(addr);
                childValidatorSet.register(signature, pubkey);
                childValidatorSet.stake{value: minStake * 2}();

                (, , , , , bool active) = childValidatorSet.getValidator(addr);

                assertEq(active, true);

                epoch = Epoch({
                    startBlock: 257 + i * 64,
                    endBlock: 320 + i * 64,
                    epochRoot: keccak256(abi.encodePacked(block.timestamp))
                });

                uptime.epochId = childValidatorSet.currentEpochId();

                vm.stopPrank();
                vm.startPrank(SYSTEM);
                childValidatorSet.commitEpoch(id, epoch, uptime);
                id++;
            }
        }

        epoch = Epoch({
            startBlock: 257 + newValidatorsCount * 64,
            endBlock: 320 + newValidatorsCount * 64,
            epochRoot: keccak256(abi.encodePacked(block.number))
        });
        uptime.epochId = childValidatorSet.currentEpochId();

        blockNumber = 0;
        pbftRound = 0;

        bytes memory fuzzyBitmap = new bytes(18);
        fuzzyBitmap[0] = "0";
        fuzzyBitmap[1] = "x";
        for (i = 0; i < 16; i++) {
            uint256 charIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 16;
            fuzzyBitmap[i + 2] = chars[charIndex];
        }

        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number)),
                bitmap: "0xff",
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 1)),
                bitmap: fuzzyBitmap,
                signature: ""
            })
        );
        inputs.push(
            IChildValidatorSetBase.DoubleSignerSlashingInput({
                epochId: 0,
                eventRoot: keccak256(abi.encodePacked(block.number)),
                currentValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                nextValidatorSetHash: keccak256(abi.encodePacked(block.number)),
                blockHash: keccak256(abi.encodePacked(block.number + 2)),
                bitmap: "0xffffffffffffffff",
                signature: ""
            })
        );

        for (i = 0; i < inputs.length; i++) {
            inputs[i].signature = abi.encode(
                block.chainid,
                blockNumber,
                inputs[i].blockHash,
                pbftRound,
                inputs[i].epochId,
                inputs[i].eventRoot,
                inputs[i].currentValidatorSetHash,
                inputs[i].nextValidatorSetHash
            );
        }

        address[] memory _validators = childValidatorSet.getCurrentValidatorSet();
        Validator[] memory validatorsInfoBeforeCommitSlash = new Validator[](_validators.length);
        for (i = 0; i < _validators.length; i++) {
            (
                uint256[4] memory blsKey,
                uint256 stake,
                ,
                uint256 commission,
                uint256 withdrawableRewards,
                bool active
            ) = childValidatorSet.getValidator(_validators[i]);
            validatorsInfoBeforeCommitSlash[i] = Validator(blsKey, stake, commission, withdrawableRewards, active);
        }
        vm.etch(0x0000000000000000000000000000000000002030, alwaysTrueBytecode);

        vm.expectEmit(true, true, true, false);
        emit NewEpoch(uptime.epochId, epoch.startBlock, epoch.endBlock, epoch.epochRoot);

        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );

        Validator[] memory validatorsInfoAfterCommitSlash = new Validator[](_validators.length);
        for (i = 0; i < _validators.length; i++) {
            (
                uint256[4] memory blsKey,
                uint256 stake,
                ,
                uint256 commission,
                uint256 withdrawableRewards,
                bool active
            ) = childValidatorSet.getValidator(_validators[i]);
            validatorsInfoAfterCommitSlash[i] = Validator(blsKey, stake, commission, withdrawableRewards, active);
        }

        assertEq(validatorsInfoBeforeCommitSlash.length, validatorsInfoAfterCommitSlash.length);

        {
            uint256 j;
            for (i = 0; i < _validators.length; i++) {
                uint256 count = 0;
                for (j = 0; j < inputs.length; j++) {
                    uint256 byteNumber = i / 8;
                    uint8 bitNumber = uint8(i % 8);
                    bytes memory bitmap = inputs[j].bitmap;
                    if (byteNumber >= bitmap.length) {
                        continue;
                    }

                    if (uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0) {
                        count++;
                    }

                    if (count > 1) {
                        assertEq(
                            validatorsInfoAfterCommitSlash[i].stake,
                            validatorsInfoBeforeCommitSlash[i].stake -
                                (validatorsInfoBeforeCommitSlash[i].stake * DOUBLE_SIGNING_SLASHING_PERCENT) /
                                100
                        );
                        // assertEq(
                        //     validatorsInfoAfterCommitSlash[i].totalStake,
                        //     validatorsInfoBeforeCommitSlash[i].totalStake -
                        //         (validatorsInfoBeforeCommitSlash[i].totalStake * DOUBLE_SIGNING_SLASHING_PERCENT) /
                        //         100
                        // );
                        break;
                    }
                }
                if (count <= 1) {
                    assertEq(validatorsInfoAfterCommitSlash[i].stake, validatorsInfoBeforeCommitSlash[i].stake);
                    // assertEq(
                    //     validatorsInfoAfterCommitSlash[i].totalStake,
                    //     validatorsInfoBeforeCommitSlash[i].totalStake
                    // );
                }
            }
        }

        {
            (uint256 startBlock, uint256 endBlock, bytes32 epochRoot) = childValidatorSet.epochs(id);
            assertEq(startBlock, epoch.startBlock);
            assertEq(endBlock, epoch.endBlock);
            assertEq(epochRoot, epoch.epochRoot);
        }

        //success try double sign for same epoch & pbftRound & key
        id++;
        epoch = Epoch({
            startBlock: 257 + newValidatorsCount * 64 + 64,
            endBlock: 320 + newValidatorsCount * 64 + 64,
            epochRoot: keccak256(abi.encodePacked(block.number))
        });

        uptime.epochId = childValidatorSet.currentEpochId();

        _validators = childValidatorSet.getCurrentValidatorSet();
        for (i = 0; i < _validators.length; i++) {
            (
                uint256[4] memory blsKey,
                uint256 stake,
                ,
                uint256 commission,
                uint256 withdrawableRewards,
                bool active
            ) = childValidatorSet.getValidator(_validators[i]);
            validatorsInfoBeforeCommitSlash[i] = Validator(blsKey, stake, commission, withdrawableRewards, active);
        }

        vm.expectEmit(true, true, true, true);
        emit NewEpoch(uptime.epochId, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
        childValidatorSet.commitEpochWithDoubleSignerSlashing(
            uptime.epochId,
            blockNumber,
            pbftRound,
            epoch,
            uptime,
            inputs
        );

        for (i = 0; i < _validators.length; i++) {
            (
                uint256[4] memory blsKey,
                uint256 stake,
                ,
                uint256 commission,
                uint256 withdrawableRewards,
                bool active
            ) = childValidatorSet.getValidator(_validators[i]);
            validatorsInfoAfterCommitSlash[i] = Validator(blsKey, stake, commission, withdrawableRewards, active);
        }

        assertEq(validatorsInfoBeforeCommitSlash.length, validatorsInfoAfterCommitSlash.length);

        for (i = 0; i < validators.length; i++) {
            assertEq(validatorsInfoAfterCommitSlash[i].stake, validatorsInfoBeforeCommitSlash[i].stake);
            // assertEq(validatorsInfoAfterCommitSlash[i].totalStake, validatorsInfoBeforeCommitSlash[i].totalStake);
        }
    }
}

contract ChildValidatorSetTest_Undelegate is Claimed {
    event Undelegated(address indexed delegator, address indexed validator, uint256 amount);

    function testCannotUndelegate_InsufficientAmount() public {
        uint256 delegatedAmount = childValidatorSet.delegationOf(alice, bob);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "undelegate", "INSUFFICIENT_BALANCE"));
        childValidatorSet.undelegate(alice, delegatedAmount + 1);
    }

    function testCannotUndelegate_LowAmount() public {
        uint256 delegatedAmount = childValidatorSet.delegationOf(alice, bob);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(StakeRequirement.selector, "undelegate", "DELEGATION_TOO_LOW"));
        childValidatorSet.undelegate(alice, delegatedAmount - 1);
    }

    function testUndelegate() public {
        uint256 delegatedAmount = childValidatorSet.delegationOf(alice, bob);

        vm.prank(bob);

        vm.expectEmit(true, false, false, true);
        emit Undelegated(bob, alice, delegatedAmount);
        childValidatorSet.undelegate(alice, delegatedAmount);
    }
}

contract ChildValidatorSetTest_SetCommission is UndelegatedState {
    function testCannotSetCommission_Unauthorized() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "VALIDATOR"));
        childValidatorSet.setCommission(MAX_COMMISSION - 1);
    }

    function testCannotSetCommission_InvalidCommission() public {
        vm.prank(alice);
        vm.expectRevert("INVALID_COMMISSION");
        childValidatorSet.setCommission(MAX_COMMISSION + 1);
    }

    function testSetCommission() public {
        vm.prank(alice);
        childValidatorSet.setCommission(MAX_COMMISSION - 1);

        (, , , uint256 commission, , ) = childValidatorSet.getValidator(alice);
        assertEq(commission, MAX_COMMISSION - 1);
    }

    function testGetTotalStake() public {
        assertEq(childValidatorSet.totalStake(), minStake * 4);
    }
}
