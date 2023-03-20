// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@utils/Test.sol";

import "contracts/child/ChildERC20.sol";
import "contracts/child/ChildERC20Predicate.sol";
import "contracts/interfaces/IStateSender.sol";
import "contracts/interfaces/IChildERC20.sol";

contract ChildERC20PredicateTest is Test {
    ChildERC20Predicate predicate;
    address rootERC20Predicate;
    address stateReceiver;
    ChildERC20 tokenTemplate;

    address alice;
    address bob;

    function setUp() public {
        predicate = new ChildERC20Predicate();

        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }
}
