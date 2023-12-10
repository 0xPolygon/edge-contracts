// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "../../interfaces/blade/staking/IStakeManager.sol";
import "../../interfaces/IStateSender.sol";
import "../../interfaces/common/IBLS.sol";
import "../../interfaces/blade/validator/IEpochManager.sol";
import "../../lib/WithdrawalQueue.sol";
import "../../blade/NetworkParams.sol";

contract StakeManager is IStakeManager, Initializable, Ownable2StepUpgradeable, ERC20VotesUpgradeable {
    using SafeERC20 for IERC20;
    using WithdrawalQueueLib for WithdrawalQueue;

    IBLS private _bls;
    IERC20 private _stakingToken;
    IEpochManager private _epochManager;
    NetworkParams private _networkParams;

    bytes32 public domain;

    mapping(address => Validator) public validators;

    // TODO: Figure out the unstake and stake withdrawal workflow (unlock period etc.)
    mapping(address => WithdrawalQueue) private _withdrawals;

    modifier onlyValidator(address validator) {
        if (!validators[validator].isActive) revert Unauthorized("VALIDATOR");
        _;
    }

    function initialize(
        address newStakingToken,
        address newBls,
        address epochManager,
        address networkParams,
        address owner,
        string memory newDomain,
        GenesisValidator[] memory genesisValidators
    ) public initializer {
        require(
            newStakingToken != address(0) &&
                newBls != address(0) &&
                epochManager != address(0) &&
                networkParams != address(0),
            "INVALID_INPUT"
        );

        __ERC20Permit_init("StakeManager");
        __ERC20_init("StakeManager", "STAKE");
        _stakingToken = IERC20(newStakingToken);
        _bls = IBLS(newBls);
        _epochManager = IEpochManager(epochManager);
        _networkParams = NetworkParams(networkParams);
        domain = keccak256(abi.encodePacked(newDomain));

        for (uint i = 0; i < genesisValidators.length; i++) {
            GenesisValidator memory validator = genesisValidators[i];
            validators[validator.addr] = Validator(validator.addr, validator.blsKey, true, true);
            _stake(validator.addr, validator.stake);
        }
        _transferOwnership(owner);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stake(uint256 amount) external onlyValidator(msg.sender) {
        _stake(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function unstake(uint256 amount) external onlyValidator(msg.sender) {
        _unstake(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStake() external view returns (uint256 amount) {
        amount = totalSupply();
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeOf(address validator) external view returns (uint256 amount) {
        amount = _stakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function whitelistValidators(address[] calldata validators_) external onlyOwner {
        uint256 length = validators_.length;
        for (uint256 i = 0; i < length; i++) {
            _addToWhitelist(validators_[i]);
        }
    }

    /**
     * @inheritdoc IStakeManager
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey, uint256 stakeAmount) external {
        Validator storage validator = validators[msg.sender];
        if (!validator.isWhitelisted) revert Unauthorized("WHITELIST");
        _verifyValidatorRegistration(msg.sender, signature, pubkey);
        validator.isActive = true;
        validator.blsKey = pubkey;
        validator.addr = msg.sender;
        _removeFromWhitelist(msg.sender);
        if (stakeAmount > 0) {
            _stake(msg.sender, stakeAmount);
        }
        emit ValidatorRegistered(msg.sender, pubkey, stakeAmount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function getValidator(address validator_) external view returns (Validator memory) {
        return validators[validator_];
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdraw() external {
        WithdrawalQueue storage queue = _withdrawals[msg.sender];
        (uint256 amount, uint256 newHead) = queue.withdrawable(_epochManager.currentEpochId());
        queue.head = newHead;

        emit StakeWithdrawn(msg.sender, amount);
        _stakingToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    // slither-disable-next-line unused-return
    function withdrawable(address account) external view returns (uint256 amount) {
        uint256 currentEpochId = _epochManager.currentEpochId();
        (amount, ) = _withdrawals[account].withdrawable(currentEpochId);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function pendingWithdrawals(address account) external view returns (uint256) {
        return _withdrawals[account].pending(_epochManager.currentEpochId());
    }

    function totalSupplyAt(uint256 epochNumber) external view returns (uint256) {
        return super.getPastTotalSupply(_epochManager.epochEndingBlocks(epochNumber));
    }

    function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256) {
        return super.getPastVotes(account, _epochManager.epochEndingBlocks(epochNumber));
    }

    function _addToWhitelist(address validator) internal {
        validators[validator].isWhitelisted = true;
        emit AddedToWhitelist(validator);
    }

    function _removeFromWhitelist(address validator) internal {
        validators[validator].isWhitelisted = false;
        emit RemovedFromWhitelist(validator);
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

    function _stake(address validator, uint256 amount) internal {
        _mint(validator, amount);
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        _stakingToken.safeTransferFrom(validator, address(this), amount);
        _delegate(validator, validator);
        // slither-disable-next-line reentrancy-events
        emit StakeAdded(validator, amount);
    }

    function _unstake(address validator, uint256 amount) internal {
        _burn(msg.sender, amount);
        emit StakeRemoved(validator, amount);

        _registerWithdrawal(msg.sender, amount);
        _removeIfValidatorUnstaked(validator);
    }

    function _registerWithdrawal(address account, uint256 amount) internal {
        _withdrawals[account].append(amount, _epochManager.currentEpochId() + _networkParams.withdrawalWaitPeriod());
    }

    /// @notice Message to sign for registration
    function _message(address signer) internal view returns (uint256[2] memory) {
        bytes memory hash = abi.encodePacked(signer, address(this), block.chainid);
        // slither-disable-next-line calls-loop
        return _bls.hashToPoint(domain, hash);
    }

    function _removeIfValidatorUnstaked(address validator) internal {
        if (_stakeOf(validator) == 0) {
            validators[validator].isActive = false;
            emit ValidatorDeactivated(validator);
        }
    }

    function _stakeOf(address validator) internal view returns (uint256 amount) {
        amount = balanceOf(validator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || to == address(0), "TRANSFER_FORBIDDEN");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _delegate(address delegator, address delegatee) internal override {
        if (delegator != delegatee) revert("DELEGATION_FORBIDDEN");
        super._delegate(delegator, delegatee);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[48] private __gap;
}
