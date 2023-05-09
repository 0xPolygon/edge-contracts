// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {ChildERC721} from "contracts/child/ChildERC721.sol";
import {ChildERC721Predicate} from "contracts/child/ChildERC721Predicate.sol";

contract ChildERC721Test is Test {
    ChildERC721 childERC721;
    ChildERC721Predicate predicate;
    address rootTokenAddress;

    address alice;
    address bob;

    string name = "TEST";
    string URI = "lorem";

    function setUp() public {
        childERC721 = new ChildERC721();
        predicate = new ChildERC721Predicate();

        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }

    function testInitialize() public {}

    function testDecimals() public {}

    function testPredicate() public {}

    function testRootToken() public {}

    function testMint() public {}

    function testMintBatch() public {}

    function testBurn() public {}

    function testBurnBatch() public {}

    function test_msgSender() public {}
}
