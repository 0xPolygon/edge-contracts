import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {RootValidatorSet} from "contracts/root/RootValidatorSet.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/IValidator.sol";

import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus {
    BLS bls;
    BN256G2 bn256G2;
    RootValidatorSet rootValidatorSet;
    CheckpointManager checkpointManager;
    uint256 public submitCounter;
    uint256 public startBlock;
    uint256 public validatorSetSize;
    address governance;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        rootValidatorSet = new RootValidatorSet();
        checkpointManager = new CheckpointManager();

        governance = makeAddr("governance");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        //initialize RootValidatorSet
        // validatorSetSize
    }
}

contract CheckpointManager_Initialize is Uninitialized {}
