// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SupernetManager.sol";
import "../../interfaces/common/IBLS.sol";
import "../../interfaces/IStateSender.sol";
import "../../interfaces/root/staking/ICustomSupernetManager.sol";
import "../../interfaces/root/IExitHelper.sol";

contract CustomSupernetManager is ICustomSupernetManager, Ownable2StepUpgradeable, SupernetManager {
    using SafeERC20 for IERC20;
    using GenesisLib for GenesisSet;

    bytes32 private constant _STAKE_SIG = keccak256("STAKE");
    bytes32 private constant _UNSTAKE_SIG = keccak256("UNSTAKE");
    bytes32 private constant _SLASH_SIG = keccak256("SLASH");

    IBLS private _bls;
    IStateSender private _stateSender;
    IERC20 private _matic;
    address private _childValidatorSet;
    address private _exitHelper;

    bytes32 public domain;

    GenesisSet private _genesis;
    mapping(address => Validator) public validators;

    modifier onlyValidator(address validator) {
        if (!validators[validator].isActive) revert Unauthorized("VALIDATOR");
        _;
    }

    /**
     * @notice Initialize the contract with initial parameters
     * @dev The StakeManager, CheckpointManager, StateSender, BLS and ExitHelper must be deployed first
     * @param initParams Initialization parameters
     */
    function initialize(SupernetInitParams calldata initParams) public initializer {
        _setInitialValues(
            initParams.newStakeManager,
            initParams.newBls,
            initParams.newStateSender,
            initParams.newMatic,
            initParams.newChildValidatorSet,
            initParams.newExitHelper,
            initParams.newDomain
        );
    }

    /**
     * @notice Initialize the contract with initial parameters on migration
     * @dev The StakeManager, CheckpointManager, StateSender, BLS and ExitHelper must be deployed first
     * @param initParams Initialization parameters
     */
    function initializeOnMigration(SupernetInitParams calldata initParams) public initializer {
        _setInitialValues(
            initParams.newStakeManager,
            initParams.newBls,
            initParams.newStateSender,
            initParams.newMatic,
            initParams.newChildValidatorSet,
            initParams.newExitHelper,
            initParams.newDomain
        );

        uint256 length = initParams.genesisSet.length;
        for (uint256 i = 0; i < length; i++) {
            GenesisValidator calldata genesisValidator = initParams.genesisSet[i];
            _genesis.insert(genesisValidator.validator, genesisValidator.initialStake);
        }

        _genesis.status = GenesisStatus.COMPLETED;

        require(
            initParams.validatorAddresses.length == initParams.validators.length,
            "ADDRESSES_AND_VALIDATORS_NOT_PAIRED"
        );

        length = initParams.validatorAddresses.length;
        for (uint256 i = 0; i < length; i++) {
            Validator calldata validator = initParams.validators[i];
            validators[initParams.validatorAddresses[i]] = validator;
        }
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function whitelistValidators(address[] calldata validators_) external onlyOwner {
        uint256 length = validators_.length;
        for (uint256 i = 0; i < length; i++) {
            _addToWhitelist(validators_[i]);
        }
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external {
        Validator storage validator = validators[msg.sender];
        if (!validator.isWhitelisted) revert Unauthorized("WHITELIST");
        _verifyValidatorRegistration(msg.sender, signature, pubkey);
        validator.blsKey = pubkey;
        validator.isActive = true;
        _removeFromWhitelist(msg.sender);
        emit ValidatorRegistered(msg.sender, pubkey);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function finalizeGenesis() external onlyOwner {
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        GenesisLib.finalize(_genesis);
        emit GenesisFinalized(_genesis.set().length);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function enableStaking() external onlyOwner {
        _genesis.enableStaking();
        emit StakingEnabled();
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function withdrawSlashedStake(address to) external onlyOwner {
        uint256 balance = _matic.balanceOf(address(this));
        _matic.safeTransfer(to, balance);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function onL2StateReceive(uint256 /*id*/, address sender, bytes calldata data) external {
        if (msg.sender != _exitHelper || sender != _childValidatorSet) revert Unauthorized("_exitHelper");
        if (bytes32(data[:32]) == _UNSTAKE_SIG) {
            (address validator, uint256 amount) = abi.decode(data[32:], (address, uint256));
            _unstake(validator, amount);
        } else if (bytes32(data[:32]) == _SLASH_SIG) {
            (, address[] memory validatorsToSlash, uint256 slashingPercentage, uint256 slashIncentivePercentage) = abi
                .decode(data, (bytes32, address[], uint256, uint256));
            _slash(id, validatorsToSlash, slashingPercentage, slashIncentivePercentage);
        }
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function genesisSet() external view returns (GenesisValidator[] memory) {
        return _genesis.set();
    }

    /**
     *
     * @inheritdoc ICustomSupernetManager
     */
    function getValidator(address validator_) external view returns (Validator memory) {
        return validators[validator_];
    }

    function _onStake(address validator, uint256 amount) internal override onlyValidator(validator) {
        if (_genesis.gatheringGenesisValidators()) {
            _genesis.insert(validator, amount);
        } else if (_genesis.completed()) {
            _stateSender.syncState(_childValidatorSet, abi.encode(_STAKE_SIG, validator, amount));
        } else {
            revert Unauthorized("Wait for genesis");
        }
    }

    function _unstake(address validator, uint256 amount) internal {
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        _stakeManager.releaseStakeOf(validator, amount);
        _removeIfValidatorUnstaked(validator);
    }

    function _slash(
        uint256 exitEventId,
        address[] memory validatorsToSlash,
        uint256 slashingPercentage,
        uint256 slashIncentivePercentage
    ) internal {
        uint256 length = validatorsToSlash.length;
        uint256 totalSlashedAmount;
        for (uint256 i = 0; i < length; ) {
            uint256 slashedAmount = (_stakeManager.stakeOf(validatorsToSlash[i], id) * slashingPercentage) / 100;
            // slither-disable-next-line reentrancy-benign,reentrancy-events,reentrancy-no-eth
            _stakeManager.slashStakeOf(validatorsToSlash[i], slashedAmount);
            _removeIfValidatorUnstaked(validatorsToSlash[i]);
            totalSlashedAmount += slashedAmount;
            unchecked {
                ++i;
            }
        }

        // contract will always have enough balance since slashStakeOf returns entire slashed amt
        uint256 rewardAmount = (totalSlashedAmount * slashIncentivePercentage) / 100;
        _matic.safeTransfer(IExitHelper(_exitHelper).caller(), rewardAmount);

        // complete slashing on child chain
        _stateSender.syncState(
            _childValidatorSet,
            abi.encode(_SLASH_SIG, exitEventId, validatorsToSlash, slashingPercentage)
        );
    }

    function _verifyValidatorRegistration(
        address signer,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) internal view {
        /// @dev signature verification succeeds if signature and pubkey are empty
        if (signature[0] == 0 && signature[1] == 0) revert InvalidSignature(signer);
        // slither-disable-next-line calls-loop
        (bool result, bool callSuccess) = _bls.verifySingle(signature, pubkey, _message(signer));
        if (!callSuccess || !result) revert InvalidSignature(signer);
    }

    /// @notice Message to sign for registration
    function _message(address signer) internal view returns (uint256[2] memory) {
        // slither-disable-next-line calls-loop
        return _bls.hashToPoint(domain, abi.encodePacked(signer, address(this), block.chainid));
    }

    function _addToWhitelist(address validator) internal {
        validators[validator].isWhitelisted = true;
        emit AddedToWhitelist(validator);
    }

    function _removeFromWhitelist(address validator) internal {
        validators[validator].isWhitelisted = false;
        emit RemovedFromWhitelist(validator);
    }

    function _removeIfValidatorUnstaked(address validator) internal {
        if (_stakeManager.stakeOf(validator, id) == 0) {
            validators[validator].isActive = false;
            emit ValidatorDeactivated(validator);
        }
    }

    function _setInitialValues(
        address newStakeManager,
        address newBls,
        address newStateSender,
        address newMatic,
        address newChildValidatorSet,
        address newExitHelper,
        string memory newDomain
    ) private {
        require(
            newStakeManager != address(0) &&
                newBls != address(0) &&
                newStateSender != address(0) &&
                newMatic != address(0) &&
                newChildValidatorSet != address(0) &&
                newExitHelper != address(0) &&
                bytes(newDomain).length != 0,
            "INVALID_INPUT"
        );
        __SupernetManager_init(newStakeManager);
        _bls = IBLS(newBls);
        _stateSender = IStateSender(newStateSender);
        _matic = IERC20(newMatic);
        _childValidatorSet = newChildValidatorSet;
        _exitHelper = newExitHelper;
        domain = keccak256(abi.encodePacked(newDomain));
        __Ownable2Step_init();
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
