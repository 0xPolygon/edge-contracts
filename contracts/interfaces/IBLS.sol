// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBLS {
    function verifySingle(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    ) external view returns (bool, bool);

    function verifyMultiple(
        uint256[2] calldata signature,
        uint256[4][] calldata pubkeys,
        uint256[2][] calldata messages
    ) external view returns (bool checkResult, bool callSuccess);

    function verifyMultipleSameMsg(
        uint256[2] calldata signature,
        uint256[4][] calldata pubkeys,
        uint256[2] calldata message
    ) external view returns (bool checkResult, bool callSuccess);

    function mapToPoint(uint256 _x) external pure returns (uint256[2] memory p);

    function isValidSignature(uint256[2] memory signature) external view returns (bool);

    function isOnCurveG1(uint256[2] memory point) external pure returns (bool _isOnCurve);

    function hashToPoint(bytes32 domain, bytes memory message) external view returns (uint256[2] memory);

    function hashToField(bytes32 domain, bytes memory messages) external view returns (uint256[2] memory);

    function expandMsgTo96(bytes32 domain, bytes memory message) external pure returns (bytes memory);
}
