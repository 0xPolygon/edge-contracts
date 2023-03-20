// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/modules/ICVSStorage.sol";
import "../../interfaces/IBLS.sol";
import "../../interfaces/IValidatorQueue.sol";
import "../../interfaces/IWithdrawalQueue.sol";
import "../../interfaces/Errors.sol";

import "../../libs/ValidatorStorage.sol";

abstract contract CVSStorage is ICVSStorage {
    using ValidatorStorageLib for ValidatorTree;

    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHILD_VALIDATOR_SET");
    uint256 public constant ACTIVE_VALIDATOR_SET_SIZE = 100;
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;
    uint256 public constant MAX_COMMISSION = 100;

    uint256 public epochSize;
    uint256 public currentEpochId;
    uint256[] public epochEndBlocks;
    uint256 public epochReward;
    uint256 public minStake;
    uint256 public minDelegation;

    IBLS public bls;

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
    function getValidator(
        address validator
    )
        external
        view
        returns (
            uint256[4] memory blsKey,
            uint256 stake,
            uint256 totalStake,
            uint256 commission,
            uint256 withdrawableRewards,
            bool active
        )
    {
        Validator memory v = _validators.get(validator);
        blsKey = v.blsKey;
        stake = v.stake;
        totalStake = v.stake + _validators.getDelegationPool(validator).supply;
        commission = v.commission;
        withdrawableRewards = v.withdrawableRewards;
        active = v.active;
    }

    function verifyValidatorRegistration(
        address signer,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) internal view {
        // slither-disable-next-line calls-loop
        (bool result, bool callSuccess) = bls.verifySingle(signature, pubkey, message(signer));
        if (!callSuccess || !result) revert InvalidSignature(signer);
    }

    /// @notice Message to sign for registration
    function message(address signer) internal view returns (uint256[2] memory) {
        // slither-disable-next-line calls-loop
        return bls.hashToPoint(DOMAIN, abi.encodePacked(signer, block.chainid));
    }
}
