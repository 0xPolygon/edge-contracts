import {CheckpointManager} from "contracts/root/CheckpointManager.sol";
import {BLS} from "contracts/common/BLS.sol";
import "contracts/interfaces/Errors.sol";
import "contracts/interfaces/IValidator.sol";

import "../utils/TestPlus.sol";

abstract contract Uninitialized is TestPlus {
    CheckpointManager checkpointManager;
    BLS bls;

    function setUp() public virtual {}
}

contract CheckpointManager_Initialize is Uninitialized {}
