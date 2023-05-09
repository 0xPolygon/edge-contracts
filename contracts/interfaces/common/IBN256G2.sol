// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBN256G2 {
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    ) external view returns (uint256, uint256, uint256, uint256);
}
