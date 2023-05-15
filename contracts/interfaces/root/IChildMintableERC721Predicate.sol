// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../child/IChildERC721.sol";
import "./IL2StateReceiver.sol";

interface IChildMintableERC721Predicate is IL2StateReceiver {
    event MintableERC721Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId
    );
    event MintableERC721DepositBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds
    );
    event MintableERC721Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId
    );
    event MintableERC721WithdrawBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds
    );
    event MintableTokenMapped(address indexed rootToken, address indexed childToken);

    function initialize(
        address newStateSender,
        address newExitHelper,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) external;

    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external;

    function withdraw(IChildERC721 childToken, uint256 tokenId) external;

    function withdrawTo(IChildERC721 childToken, address receiver, uint256 tokenId) external;

    function withdrawBatch(IChildERC721 childToken, address[] calldata receivers, uint256[] calldata tokenIds) external;
}
