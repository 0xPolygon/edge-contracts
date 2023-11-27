// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IL2StateReceiver.sol";

interface IRootERC721Predicate is IL2StateReceiver {
    event ERC721Deposit(
        address indexed rootToken,
        address indexed childToken,
        address depositor,
        address indexed receiver,
        uint256 tokenId
    );
    event ERC721DepositBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed depositor,
        address[] receivers,
        uint256[] tokenIds
    );
    event ERC721Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address withdrawer,
        address indexed receiver,
        uint256 tokenId
    );
    event ERC721WithdrawBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed withdrawer,
        address[] receivers,
        uint256[] tokenIds
    );
    event TokenMapped(address indexed rootToken, address indexed childToken);

    /**
     * @notice Function to deposit tokens from the depositor to themselves on the child chain
     * @param rootToken Address of the root token being deposited
     * @param tokenId Index of the NFT to deposit
     */
    function deposit(IERC721Metadata rootToken, uint256 tokenId) external;

    /**
     * @notice Function to deposit tokens from the depositor to another address on the child chain
     * @param rootToken Address of the root token being deposited
     * @param tokenId Index of the NFT to deposit
     */
    function depositTo(IERC721Metadata rootToken, address receiver, uint256 tokenId) external;

    /**
     * @notice Function to deposit tokens from the depositor to other addresses on the child chain
     * @param rootToken Address of the root token being deposited
     * @param receivers Addresses of the receivers on the child chain
     * @param tokenIds Indeices of the NFTs to deposit
     */
    function depositBatch(
        IERC721Metadata rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Function to be used for token mapping
     * @param rootToken Address of the root token to map
     * @return childToken Address of the mapped child token
     * @dev Called internally on deposit if token is not mapped already
     */
    function mapToken(IERC721Metadata rootToken) external returns (address childToken);
}
