// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../child/IChildERC1155.sol";
import "./IL2StateReceiver.sol";

interface IChildMintableERC1155Predicate is IL2StateReceiver {
    event MintableERC1155Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount
    );
    event MintableERC1155DepositBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event MintableERC1155Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount
    );
    event MintableERC1155WithdrawBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event MintableTokenMapped(address indexed rootToken, address indexed childToken);

    function initialize(
        address newStateSender,
        address newExitHelper,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) external;

    function withdraw(IChildERC1155 childToken, uint256 tokenId, uint256 amount) external;

    function withdrawTo(IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external;
}
