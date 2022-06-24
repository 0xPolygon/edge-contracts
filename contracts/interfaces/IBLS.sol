// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBLS {
    function verifySingle(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    ) external view returns (bool, bool);

    function hashToPoint(bytes32 domain, bytes memory message)
        external
        view
        returns (uint256[2] memory);
}
