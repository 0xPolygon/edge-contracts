// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/IValidator.sol";
import "contracts/common/Merkle.sol";
import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus {
    CheckpointManager checkpointManager;
    BLS bls;
    BN256G2 bn256G2;

    uint256 submitCounter;
    uint256 validatorSetSize;
    address[] public validatorSet;

    address public admin;
    address public alice;
    address public bob;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        checkpointManager = new CheckpointManager();

        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }
}

contract CheckpointManager_Initialize is Uninitialized {
    function testInitialize() public {
        assertEq(childValidatorSet.totalActiveStake(), 0);

        IChildValidatorSetBase.InitStruct memory init = IChildValidatorSetBase.InitStruct(
            epochReward,
            minStake,
            minDelegation,
            64
        );

        childValidatorSet.initialize(
            init,
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
