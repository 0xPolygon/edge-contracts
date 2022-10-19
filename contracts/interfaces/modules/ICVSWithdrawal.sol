// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICVSWithdrawal {
    event WithdrawalRegistered(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, address indexed to, uint256 amount);

    /**
     * @notice Withdraws sender's withdrawable amount to specified address.
     * @param to Address to withdraw to
     */
    function withdraw(address to) external;

    /**
     * @notice Calculates how much can be withdrawn for account in this epoch.
     * @param account The account to calculate amount for
     * @return Amount withdrawable (in MATIC wei)
     */
    function withdrawable(address account) external view returns (uint256);

    /**
     * @notice Calculates how much is yet to become withdrawable for account.
     * @param account The account to calculate amount for
     * @return Amount not yet withdrawable (in MATIC wei)
     */
    function pendingWithdrawals(address account) external view returns (uint256);
}
