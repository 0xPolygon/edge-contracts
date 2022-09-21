// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/modules/ICVSWithdrawal.sol";
import "./CVSStorage.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../libs/WithdrawalQueue.sol";

abstract contract CVSWithdrawal is ICVSWithdrawal, CVSStorage, ReentrancyGuardUpgradeable {
    using WithdrawalQueueLib for WithdrawalQueue;

    /**
     * @inheritdoc ICVSWithdrawal
     */
    function withdraw(address to) external nonReentrant {
        assert(to != address(0));
        WithdrawalQueue storage queue = _withdrawals[msg.sender];
        (uint256 amount, uint256 newHead) = queue.withdrawable(currentEpochId);
        queue.head = newHead;
        emit Withdrawal(msg.sender, to, amount);
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        require(success, "WITHDRAWAL_FAILED");
    }

    /**
     * @inheritdoc ICVSWithdrawal
     */
    function withdrawable(address account) external view returns (uint256 amount) {
        (amount, ) = _withdrawals[account].withdrawable(currentEpochId);
    }

    /**
     * @inheritdoc ICVSWithdrawal
     */
    function pendingWithdrawals(address account) external view returns (uint256) {
        return _withdrawals[account].pending(currentEpochId);
    }

    function _registerWithdrawal(address account, uint256 amount) internal {
        _withdrawals[account].append(amount, currentEpochId + WITHDRAWAL_WAIT_PERIOD);
        emit WithdrawalRegistered(account, amount);
    }
}
