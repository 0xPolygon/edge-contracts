// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library SafeMathInt {
    /**
     * @notice converts an int256 to uint256
     * @param a int256 to convert
     * @return uint256 of the input
     */
    // slither-disable-next-line dead-code
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        assert(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    /**
     * @notice converts a uint256 to int256
     * @param a the uint256 to convert
     * @return int256 of the input
     */
    // slither-disable-next-line dead-code
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        assert(b >= 0);
        return b;
    }
}
