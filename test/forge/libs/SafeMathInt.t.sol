// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeMathInt, SafeMathUint} from "contracts/libs/SafeMathInt.sol";

import "../utils/TestPlus.sol";

contract SafeMathIntTest is TestPlus {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    function testToUint256Safe(int256 a) public {
        if (a < 0) vm.expectRevert(stdError.assertionError);

        assertEq(a.toUint256Safe(), uint256(a));
    }

    function testToInt256Safe(uint256 a) public {
        if (a > uint256(type(int256).max)) vm.expectRevert(stdError.assertionError);

        assertEq(a.toInt256Safe(), int256(a));
    }
}
