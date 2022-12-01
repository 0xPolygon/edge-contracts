// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/ICheckpointManager.sol";

import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus {
    CheckpointManager checkpointManager;
    BLS bls;
    BN256G2 bn256G2;

    uint256 submitCounter;
    uint256 validatorSetSize;
    ICheckpointManager.Validator[] public validatorSet;

    address public admin;
    address public alice;
    address public bob;
    bytes32 public domain;
    uint256[2][] public aggMessagePoints;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        checkpointManager = new CheckpointManager();

        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        domain = keccak256(abi.encodePacked(block.timestamp));

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/root/generateMsg.ts";
        cmd[3] = vm.toString(abi.encode(domain));
        bytes memory out = vm.ffi(cmd);

        ICheckpointManager.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp) = abi.decode(out, (uint256, ICheckpointManager.Validator[]));

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        checkpointManager.initialize(bls, bn256G2, domain, validatorSet);
    }
}

contract CheckpointManager_Initialize is Uninitialized {
    function testInitialize() public {
        checkpointManager.initialize(bls, bn256G2, domain, validatorSet);

        assertEq(keccak256(abi.encode(checkpointManager.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(checkpointManager.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        assertEq(checkpointManager.domain(), domain);
        assertEq(checkpointManager.currentValidatorSetLength(), validatorSetSize);
        for (uint256 i = 0; i < validatorSetSize; i++) {
            (address _address, uint256 votingPower) = checkpointManager.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}
