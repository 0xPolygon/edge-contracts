// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {RootERC20Predicate} from "contracts/root/RootERC20Predicate.sol";
import {ChildERC20} from "contracts/child/ChildERC20.sol";
import {StateSenderHelper} from "./StateSender.t.sol";
import {Initialized} from "./ExitHelper.t.sol";
import {PredicateHelper} from "./PredicateHelper.t.sol";
import "forge-std/console2.sol";

abstract contract ChildERC20Helper {
    ChildERC20 childERC20;

    function setUp() public virtual {
        childERC20 = new ChildERC20();
        // address rootToken_,
        // string calldata name_,
        // string calldata symbol_,
        // uint8 decimals_
        // childERC20.initialize(address(0), )
    }
}

contract RootERC20PredicateTest is PredicateHelper, Test {
    RootERC20Predicate rootERC20Predicate;

    function setUp() public virtual override {
        super.setUp();

        rootERC20Predicate = new RootERC20Predicate();
        address newChildERC20Predicate = makeAddr("newChildERC20Predicate");
        address newChildTokenTemplate = makeAddr("newChildTokenTemplate");
        address nativeTokenRootAddress = makeAddr("newStateSender");
        rootERC20Predicate.initialize(
            address(stateSender),
            address(exitHelper),
            newChildERC20Predicate,
            newChildTokenTemplate,
            nativeTokenRootAddress
        );
    }

    function testDepositToNative() public {
        address alice = makeAddr("alice");
        uint256 startBalance = 100000000000000;
        vm.startPrank(alice);
        vm.deal(alice, startBalance);
        console2.log(address(checkpointManager));
        console2.log(address(exitHelper));

        // rootERC20Predicate.depositNativeTo{value: 1}(alice);
    }
}
