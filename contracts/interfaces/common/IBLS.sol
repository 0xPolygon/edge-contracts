// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBLS {
    /**
     * @notice verifies a single signature
     * @param signature 64-byte G1 group element (small sig)
     * @param pubkey 128-byte G2 group element (big pubkey)
     * @param message message signed to produce signature
     * @return bool sig verification
     * @return bool indicating call success
     */
    function verifySingle(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    ) external view returns (bool, bool);

    /**
     * @notice verifies multiple non-aggregated signatures where each message is unique
     * @param signature 64-byte G1 group element (small sig)
     * @param pubkeys array of 128-byte G2 group element (big pubkey)
     * @param messages array of messages signed to produce signature
     * @return checkResult bool indicating sig verification
     * @return callSuccess bool indicating call success
     */
    function verifyMultiple(
        uint256[2] calldata signature,
        uint256[4][] calldata pubkeys,
        uint256[2][] calldata messages
    ) external view returns (bool checkResult, bool callSuccess);

    /**
     * @notice verifies an aggregated signature where the same message is signed
     * @param signature 64-byte G1 group element (small sig)
     * @param pubkeys array of 128-byte G2 group element (big pubkey)
     * @param message message signed by all to produce signature
     * @return checkResult sig verification
     * @return callSuccess indicating call success
     */
    function verifyMultipleSameMsg(
        uint256[2] calldata signature,
        uint256[4][] calldata pubkeys,
        uint256[2] calldata message
    ) external view returns (bool checkResult, bool callSuccess);

    /**
     * @notice maps a field element to the curve
     * @param _x a valid field element
     * @return p the point on the curve the point is mapped to
     */
    function mapToPoint(uint256 _x) external pure returns (uint256[2] memory p);

    /**
     * @notice checks if a signature is formatted correctly and valid
     * @dev will revert if improperly formatted, will return false if invalid
     * @param signature the BLS signature
     * @return bool indicating if the signature is valid or not
     */
    function isValidSignature(uint256[2] memory signature) external view returns (bool);

    /**
     * @notice checks if point in the finite field Fq (x,y) is on the G1 curve
     * @param point array with x and y values of the point
     * @return _isOnCurve bool indicating if the point is on the curve or not
     */
    function isOnCurveG1(uint256[2] memory point) external pure returns (bool _isOnCurve);

    /**
     * @notice checks if point in the finite field Fq (x,y) is on the G2 curve
     * @param point array with x and y values of the point
     * @return _isOnCurve bool indicating if the point is on the curve or not
     */
    function isOnCurveG2(uint256[4] memory point) external pure returns (bool _isOnCurve);

    /**
     * @notice hashes an arbitrary message to a point on the curve
     * @dev Fouque-Tibouchi Hash to Curve
     * @param domain domain separator for the hash
     * @param message the message to map
     * @return uint256[2] (x,y) point on the curve that the message maps to
     */
    function hashToPoint(bytes32 domain, bytes memory message) external view returns (uint256[2] memory);

    /**
     * @notice hashes an arbitrary message to a field element
     * @param domain domain separator for the hash
     * @param messages the messages to map
     * @return uint256[2] (x,y) point of the field element that the message maps to
     */
    function hashToField(bytes32 domain, bytes memory messages) external view returns (uint256[2] memory);

    /**
     * @notice pads messages less than 96 bytes to 96 bytes for hashing
     * @param domain domain separator for the hash
     * @param message the message to pad
     * @return bytes the padded message
     */
    function expandMsgTo96(bytes32 domain, bytes memory message) external pure returns (bytes memory);
}
