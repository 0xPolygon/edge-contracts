// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChildValidatorSet} from "contracts/child/ChildValidatorSet.sol";
import {System} from "contracts/child/ChildValidatorSet.sol";
import {BLS} from "contracts/common/BLS.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/IValidator.sol";

import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus, System {
    ChildValidatorSet childValidatorSet;
    BLS bls;

    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;
    address public admin;
    address[] validatorAddresses;
    uint256[4][] validatorPubkeys;
    uint256[] validatorStakes;
    uint256[2] messagePoint;
    address governance;

    function setUp() public virtual {
        epochReward = 0.0000001 ether;
        minStake = 10000;
        minDelegation = 10000;

        bls = new BLS();
        childValidatorSet = new ChildValidatorSet();

        admin = makeAddr("admin");
        governance = makeAddr("governance");

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
