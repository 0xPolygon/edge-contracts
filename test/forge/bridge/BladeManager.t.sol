// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import "contracts/bridge/StateSender.sol";
import {ExitHelper} from "contracts/bridge/ExitHelper.sol";
import {BladeManager, GenesisAccount} from "contracts/bridge/BladeManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {RootERC20Predicate} from "contracts/bridge/RootERC20Predicate.sol";
import "contracts/interfaces/Errors.sol";

abstract contract Uninitialized is Test {
    MockERC20 token;
    RootERC20Predicate rootERC20Predicate;
    BladeManager bladeManager;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address jim = makeAddr("jim");

    function setUp() public virtual {
        token = new MockERC20();
        bladeManager = new BladeManager();
        rootERC20Predicate = new RootERC20Predicate();
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();

        GenesisAccount[] memory validators = new GenesisAccount[](3);
        validators[0] = GenesisAccount({
            addr: bob,
            stakedTokens: 0,
            preminedTokens: 0,
            isValidator: true
        });
        validators[1] = GenesisAccount({
            addr: alice,
            stakedTokens: 0,
            preminedTokens: 0,
            isValidator: true
        });
        validators[2] = GenesisAccount({
            addr: jim,
            stakedTokens: 0,
            preminedTokens: 0,
            isValidator: true
        });

        bladeManager.initialize(
            address(rootERC20Predicate),
           validators
        );
    }
}

contract BladeManager_PremineInitialized is Initialized {
    uint256 balance = 100 ether;
    event GenesisBalanceAdded(address indexed account, uint256 indexed amount);

    address childERC20Predicate;
    address childTokenTemplate;

    function setUp() public virtual override {
        super.setUp();
        token.mint(bob, balance);
        childERC20Predicate = makeAddr("childERC20Predicate");
        childTokenTemplate = makeAddr("childTokenTemplate");
        rootERC20Predicate.initialize(
            address(new StateSender()),
            address(new ExitHelper()),
            childERC20Predicate,
            childTokenTemplate,
            address(token)
        );
    }

    function test_addGenesisBalance_successful() public {
        vm.startPrank(bob);
        token.approve(address(bladeManager), balance);
        vm.expectEmit(true, true, true, true);
        emit GenesisBalanceAdded(bob, balance);
        bladeManager.addGenesisBalance(balance/2, balance/2);

        GenesisAccount[] memory genesisAccounts = bladeManager.genesisSet();
        assertEq(genesisAccounts.length, 3, "should set genesisSet");
        GenesisAccount memory account = genesisAccounts[0];
        assertEq(account.addr, bob, "should set validator address");
        assertEq(account.stakedTokens, balance/2, "should be equal to added staked amount");
        assertEq(account.preminedTokens, balance/2, "should be equal to added staked amount");
    }

    function test_addGenesisBalance_genesisSetFinalizedRevert() public {
        bladeManager.finalizeGenesis();
        vm.expectRevert("BladeManager: CHILD_CHAIN_IS_LIVE");
        bladeManager.addGenesisBalance(balance/2, balance/2);
    }

    function test_addGenesisBalance_invalidAmountRevert() public {
        vm.expectRevert("BladeManager: INVALID_AMOUNT");
        bladeManager.addGenesisBalance(0, 0);
    }

    function test_addGenesisBalance_notValidator() public {
        address john = makeAddr("john");
        vm.startPrank(john);
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, "BladeManager: TRYING_TO_STAKE_WHEN_NOT_A_VALIDATOR")
        );
        bladeManager.addGenesisBalance(0, 100 ether);
    }
}

contract BladeManager_FinalizeGenesis is Initialized {
    event GenesisFinalized(uint256 amountValidators);

    function test_RevertNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        bladeManager.finalizeGenesis();
    }

    function test_SuccessFinaliseGenesis() public {
        vm.expectEmit(true, true, true, true);
        emit GenesisFinalized(3);
        bladeManager.finalizeGenesis();
    }
}

contract BladeManager_UndefinedRootERC20Predicate is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
    }
    function test_initialize_revertUndefinedRootERC20Predicate() public {
        vm.expectRevert("INVALID_INPUT");

        bladeManager.initialize(address(0), new GenesisAccount[](0));
    }
       
    function test_addGenesisBalance_revertUndefinedRootERC20Predicate() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, "BladeManager: UNDEFINED_ROOT_ERC20_PREDICATE")
        );
        bladeManager.addGenesisBalance(100 ether, 100 ether);
    }
}