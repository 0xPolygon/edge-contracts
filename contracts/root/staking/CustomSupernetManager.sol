// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/SupernetManager.sol";
import "../../interfaces/common/IBLS.sol";
import "../../interfaces/IStateSender.sol";
import "../../interfaces/root/staking/ICustomSupernetManager.sol";

contract CustomSupernetManager is ICustomSupernetManager, Ownable2StepUpgradeable, SupernetManager {
    using SafeERC20 for IERC20;
    using GenesisLib for GenesisSet;

    bytes32 private constant STAKE_SIG = keccak256("STAKE");
    bytes32 private constant UNSTAKE_SIG = keccak256("UNSTAKE");
    bytes32 private constant SLASH_SIG = keccak256("SLASH");
    uint256 public constant SLASHING_PERCENTAGE = 50;

    IBLS private BLS;
    IStateSender private STATE_SENDER;
    IERC20 private MATIC;
    address private CHILD_VALIDATOR_SET;
    address private EXIT_HELPER;

    bytes32 public DOMAIN;

    GenesisSet private _genesis;
    mapping(address => Validator) public validators;

    modifier onlyValidator(address validator) {
        if (!validators[validator].isActive) revert Unauthorized("VALIDATOR");
        _;
    }

    function initialize(
        address stakeManager,
        address bls,
        address stateSender,
        address matic,
        address childValidatorSet,
        address exitHelper,
        string memory domain
    ) public initializer {
        __SupernetManager_init(stakeManager);
        BLS = IBLS(bls);
        STATE_SENDER = IStateSender(stateSender);
        MATIC = IERC20(matic);
        CHILD_VALIDATOR_SET = childValidatorSet;
        EXIT_HELPER = exitHelper;
        DOMAIN = keccak256(abi.encodePacked(domain));
        __Ownable2Step_init();
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
        _genesis.finalize();
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
        uint256 balance = MATIC.balanceOf(address(this));
        MATIC.safeTransfer(to, balance);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function onL2StateReceive(uint256 /*id*/, address sender, bytes calldata data) external {
        if (msg.sender != EXIT_HELPER || sender != CHILD_VALIDATOR_SET) revert Unauthorized("EXIT_HELPER");
        if (bytes32(data[:32]) == UNSTAKE_SIG) {
            (address validator, uint256 amount) = abi.decode(data[32:], (address, uint256));
            _unstake(validator, amount);
        } else if (bytes32(data[:32]) == SLASH_SIG) {
            address validator = abi.decode(data[32:], (address));
            _slash(validator);
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
            STATE_SENDER.syncState(CHILD_VALIDATOR_SET, abi.encode(STAKE_SIG, validator, amount));
        } else {
            revert Unauthorized("Wait for genesis");
        }
    }

    function _unstake(address validator, uint256 amount) internal {
        STAKE_MANAGER.releaseStakeOf(validator, amount);
        _removeIfValidatorUnstaked(validator);
    }

    function _slash(address validator) internal {
        uint256 stake = STAKE_MANAGER.stakeOf(validator, id);
        uint256 slashedAmount = (stake * SLASHING_PERCENTAGE) / 100;
        STAKE_MANAGER.slashStakeOf(validator, slashedAmount);
        _removeIfValidatorUnstaked(validator);
    }

    function _verifyValidatorRegistration(
        address signer,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) internal view {
        _verifyNotEmpty(signer, signature, pubkey);
        // slither-disable-next-line calls-loop
        (bool result, bool callSuccess) = BLS.verifySingle(signature, pubkey, _message(signer));
        if (!callSuccess || !result) revert InvalidSignature(signer);
    }

    /// @dev signature verification succeeds if signature and pubkey are empty
    function _verifyNotEmpty(address signer, uint256[2] calldata signature, uint256[4] calldata pubkey) internal pure {
        bytes32 emptySignature = keccak256(abi.encodePacked([uint256(0), uint256(0)]));
        bytes32 emptyPubkey = keccak256(abi.encodePacked([uint256(0), uint256(0), uint256(0), uint256(0)]));
        if (
            keccak256(abi.encodePacked(signature)) == emptySignature &&
            keccak256(abi.encodePacked(pubkey)) == emptyPubkey
        ) revert InvalidSignature(signer);
    }

    /// @notice Message to sign for registration
    function _message(address signer) internal view returns (uint256[2] memory) {
        // slither-disable-next-line calls-loop
        return BLS.hashToPoint(DOMAIN, abi.encodePacked(signer, address(this), block.chainid));
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
        if (STAKE_MANAGER.stakeOf(validator, id) == 0) {
            validators[validator].isActive = false;
            emit ValidatorDeactivated(validator);
        }
    }
}
