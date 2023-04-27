// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
// import "contracts/common/BLS.sol";
// import "contracts/root/StateSender.sol";
import {StakeManager} from "contracts/root/staking/StakeManager.sol";
import {SupernetManager} from "contracts/root/staking/lib/SupernetManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";

abstract contract Uninitialized is Test {
    // BLS bls;
    // StateSender stateSender;
    // address childValidatorSet;
    // address exitHelper;
    // string constant DOMAIN = "CUSTOM_SUPERNET_MANAGER";
    MockERC20 token;
    StakeManager stakeManager;
    SupernetManager supernetManager;

    function setUp() public virtual {
        // bls = new BLS();
        // stateSender = new StateSender();
        // childValidatorSet = makeAddr("childValidatorSet");
        // childValidatorSet = makeAddr("exitHelper");
        token = new MockERC20();
        stakeManager = new StakeManager();
        supernetManager = new SupernetManager();
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        stakeManager.initialize(address(token));
        supernetManager.initialize(address(stakeManager));
    }
}

abstract contract Registered is Initialized {
    uint256 maxAmount = 1000000 ether;
    SupernetManager supernetManager2;
    uint256 id;
    uint256 id2;
    address alice;

    function setUp() public virtual override {
        super.setUp();
        alice = makeAddr("alice");
        supernetManager2 = new SupernetManager();
        supernetManager2.initialize(address(stakeManager));
        id = stakeManager.registerChildChain(address(supernetManager));
        id2 = stakeManager.registerChildChain(address(supernetManager2));
        token.mint(address(this), maxAmount * 2);
        token.mint(alice, maxAmount);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(alice);
        token.approve(address(stakeManager), type(uint256).max);
    }
}

abstract contract Staked is Registered {
    function setUp() public virtual override {
        super.setUp();
        stakeManager.stakeFor(1, maxAmount);
    }
}

contract StakeManager_Initialize is Uninitialized {
    function testInititialize() public {
        stakeManager.initialize(address(token));
    }
}

contract StakeManager_Register is Initialized, StakeManager {
    function test_RevertFailingCallback() public {
        vm.expectRevert(bytes(""));
        stakeManager.registerChildChain(address(token));
    }

    function test_RegisterChildChain() public {
        vm.expectEmit(true, true, true, true);
        emit ChildManagerRegistered(1, address(supernetManager));
        uint256 id = stakeManager.registerChildChain(address(supernetManager));
        assertEq(stakeManager.idFor(address(supernetManager)), id, "id mismatch on stake manager");
        assertEq(address(stakeManager.managerOf(id)), address(supernetManager), "manager mismatch on stake manager");
        assertEq(supernetManager.id(), id, "id mismatch on supernet manager");
        assertGt(id, 0, "id is zero");
    }
}

contract StakeManager_StakeFor is Registered, StakeManager {
    function test_StakeFor(uint256 amount) public {
        vm.assume(amount <= maxAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeAdded(id, address(this), amount);
        stakeManager.stakeFor(id, amount);
        assertEq(stakeManager.totalStake(), amount, "total stake mismatch");
        assertEq(stakeManager.totalStakeOfChild(id), amount, "total stake of child mismatch");
        assertEq(stakeManager.totalStakeOf(address(this)), amount, "total stake of mismatch");
        assertEq(stakeManager.stakeOf(address(this), 1), amount, "stake of mismatch");
    }
}
