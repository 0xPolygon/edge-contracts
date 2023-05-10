// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "./IL2StateReceiver.sol";

interface IRootERC1155Predicate is IL2StateReceiver {
    struct ERC1155BridgeEvent {
        address rootToken;
        address childToken;
        address sender;
        address receiver;
    }

    event ERC1155Deposit(
        address indexed rootToken,
        address indexed childToken,
        address depositor,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount
    );
    event ERC1155DepositBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed depositor,
        address[] receivers,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event ERC1155Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address withdrawer,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount
    );
    event ERC1155WithdrawBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed withdrawer,
        address[] receivers,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event TokenMapped(address indexed rootToken, address indexed childToken);

    /**
     * @notice Function to deposit tokens from the depositor to themselves on the child chain
     * @param rootToken Address of the root token being deposited
     * @param tokenId Index of the NFT to deposit
     * @param amount Amount to deposit
     */
    function deposit(IERC1155MetadataURI rootToken, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Function to deposit tokens from the depositor to another address on the child chain
     * @param rootToken Address of the root token being deposited
     * @param tokenId Index of the NFT to deposit
     * @param amount Amount to deposit
     */
    function depositTo(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Function to deposit tokens from the depositor to other addresses on the child chain
     * @param rootToken Address of the root token being deposited
     * @param receivers Addresses of the receivers on the child chain
     * @param tokenIds Indeices of the NFTs to deposit
     * @param amounts Amounts to deposit
     */
    function depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Function to be used for token mapping
     * @param rootToken Address of the root token to map
     * @return childToken Address of the mapped child token
     * @dev Called internally on deposit if token is not mapped already
     */
    function mapToken(IERC1155MetadataURI rootToken) external returns (address childToken);
}
