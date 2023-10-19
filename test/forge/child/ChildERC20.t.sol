// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {ChildERC20Predicate} from "contracts/child/ChildERC20Predicate.sol";

contract ChildERC20Test is Test {
    ChildERC20 childERC20;
    ChildERC20Predicate predicate;
    address rootTokenAddress;

    address alice;
    address bob;

    string name = "TEST";
    uint8 decimals = 18;

    function setUp() public {
        childERC20 = ChildERC20(proxify("ChildERC20.sol", ""));
        predicate = ChildERC20Predicate(proxify("ChildERC20Predicate.sol", ""));

        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }

    function testInitialize() public {}

    function testDecimals() public {}

    function testPredicate() public {}

    function testRootToken() public {}

    function testMint() public {}

    function testBurn() public {}

    function test_msgSender() public {}
}
