// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IStateReceiver.sol";
import "./IChildERC20.sol";

interface IChildERC20Predicate is IStateReceiver {
    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress
    ) external;

    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external;

    function withdraw(IChildERC20 childToken, uint256 amount) external;

    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external;
}
