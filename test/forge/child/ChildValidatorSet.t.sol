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
    address[] validatorAddresses;
    uint256[4][] validatorPubkeys;
    uint256[] validatorStakes;
    uint256[2] messagePoint;
    address governance;
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
        governance = makeAddr("governance");
        alice = makeAddr("Alice");

        validatorAddresses.push(admin);
        validatorPubkeys.push([0, 0, 0, 0]);
        validatorStakes.push(minStake * 2);
        messagePoint[0] = 0;
        messagePoint[1] = 0;
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public override {
        super.setUp();

        vm.prank(SYSTEM);

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

contract ChildValidatorSetTest_Initialized is Initialized {
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

    function testCannotRegister_NotWhitelisted() public {
        bytes message = "polygon-v3-validator";
    }
}
