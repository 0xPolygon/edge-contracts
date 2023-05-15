// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IStateReceiver.sol";

interface IRootMintableERC20Predicate is IStateReceiver {
    event L2MintableERC20Deposit(
        address indexed rootToken,
        address indexed childToken,
        address depositor,
        address indexed receiver,
        uint256 amount
    );
    event L2MintableERC20Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address withdrawer,
        address indexed receiver,
        uint256 amount
    );
    event L2MintableTokenMapped(address indexed rootToken, address indexed childToken);

    /**
     * @notice Function to deposit tokens from the depositor to themselves on the child chain
     * @param rootToken Address of the root token being deposited
     * @param amount Amount to deposit
     */
    function deposit(IERC20Metadata rootToken, uint256 amount) external;

    /**
     * @notice Function to deposit tokens from the depositor to another address on the child chain
     * @param rootToken Address of the root token being deposited
     * @param amount Amount to deposit
     */
    function depositTo(IERC20Metadata rootToken, address receiver, uint256 amount) external;

    /**
     * @notice Function to be used for token mapping
     * @param rootToken Address of the root token to map
     * @dev Called internally on deposit if token is not mapped already
     * @return address Address of the child token
     */
    function mapToken(IERC20Metadata rootToken) external returns (address);
}
