// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/modules/ICVSStorage.sol";
import "../../interfaces/IBLS.sol";
import "../../interfaces/IValidatorQueue.sol";
import "../../interfaces/IWithdrawalQueue.sol";

import "../../libs/ValidatorStorage.sol";

abstract contract CVSStorage is ICVSStorage {
    using ValidatorStorageLib for ValidatorTree;

    bytes32 public constant NEW_VALIDATOR_SIG = 0xbddc396dfed8423aa810557cfed0b5b9e7b7516dac77d0b0cdf3cfbca88518bc;
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100; // might want to change later!
    uint256 public constant MAX_VALIDATOR_SET_SIZE = 500;
    uint256 public constant REWARD_PRECISION = 10**18;
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;
    // more granular commission?
    uint256 public constant MAX_COMMISSION = 100;

    uint256 public currentEpochId;
    uint256[] public epochEndBlocks;
    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;

    IBLS public bls;

    /// @notice Message to sign for registration
    uint256[2] public message;

    // slither-disable-next-line naming-convention
    ValidatorTree internal _validators;
    // slither-disable-next-line naming-convention
    ValidatorQueue internal _queue;
    // slither-disable-next-line naming-convention
    mapping(address => WithdrawalQueue) internal _withdrawals;

    mapping(uint256 => Epoch) public epochs;
    mapping(address => bool) public whitelist;

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;

    /**
     * @inheritdoc ICVSStorage
     */
    function getValidator(address validator) public view returns (Validator memory) {
        return _validators.get(validator);
    }
}
