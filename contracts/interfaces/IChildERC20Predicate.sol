// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IChildERC20.sol";
import "./IStateReceiver.sol";

interface IChildERC20Predicate is IStateReceiver {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress,
        string calldata newNativeTokenName,
        string calldata newNativeTokenSymbol,
        uint8 newNativeTokenDecimals
    ) external;

    function deployChildToken(
        address rootToken,
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external;

    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external;

    function withdraw(IChildERC20 childToken, uint256 amount) external;

    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external;
}
