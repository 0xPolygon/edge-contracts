// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {ChildERC1155} from "contracts/child/ChildERC1155.sol";
import {ChildERC1155Predicate} from "contracts/child/ChildERC1155Predicate.sol";

contract ChildERC1155Test is Test {
    ChildERC1155 childERC1155;
    ChildERC1155Predicate predicate;
    address rootTokenAddress;

    address alice;
    address bob;

    string URI = "lorem";

    function setUp() public {
        childERC1155 = new ChildERC1155();
        predicate = new ChildERC1155Predicate();

        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }

    function testInitialize() public {}

    function testDecimals() public {}

    function testPredicate() public {}

    function testRootToken() public {}

    function testMint() public {}

    function testMintBatch() public {}

    function testMintBatch2() public {}

    function testBurn() public {}

    function testBurnBatch() public {}

    function test_msgSender() public {}
}
