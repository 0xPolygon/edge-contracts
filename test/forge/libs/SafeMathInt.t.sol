// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {SafeMathInt, SafeMathUint} from "contracts/lib/SafeMathInt.sol";

contract SafeMathIntTest is Test {
    SafeMathUser safeMathUser;

    function setUp() public {
        safeMathUser = new SafeMathUser();
    }

    function testToUint256Safe(int256 a) public {
        if (a < 0) {
            vm.expectRevert(stdError.assertionError);
            safeMathUser.toUint256Safe(a);
        } else assertEq(safeMathUser.toUint256Safe(a), uint256(a));
    }

    function testToInt256Safe(uint256 a) public {
        if (a > uint256(type(int256).max)) {
            vm.expectRevert(stdError.assertionError);
            safeMathUser.toInt256Safe(a);
        } else assertEq(safeMathUser.toInt256Safe(a), int256(a));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract SafeMathUser {
    function toUint256Safe(int256 a) external pure returns (uint256) {
        uint256 r = SafeMathInt.toUint256Safe(a);
        return r;
    }

    function toInt256Safe(uint256 a) external pure returns (int256) {
        int256 r = SafeMathUint.toInt256Safe(a);
        return r;
    }
}
