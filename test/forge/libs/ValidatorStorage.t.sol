// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ValidatorStorageLib, AmountZero, Exists, NotFound} from "contracts/libs/ValidatorStorage.sol";
import {RewardPool, Validator, Node, ValidatorTree} from "contracts/interfaces/IValidator.sol";

import "../utils/TestPlus.sol";

abstract contract EmptyState is TestPlus {
    address account;
    Validator validator;
    ValidatorTree tree;

    function setUp() public virtual {
        account = makeAddr("account");
        validator = _createValidator(1 ether);
    }
}

contract ValidatorStorageTest_EmptyState is EmptyState {
    using ValidatorStorageLib for ValidatorTree;

    function testCannotInsert_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        tree.insert(address(0), validator);
    }

    function testCannotInsert_InvalidTotalStake() public {
        validator.stake = validator.totalStake + 1;

        vm.expectRevert(stdError.assertionError);
        tree.insert(account, validator);
    }

    function testCannotInsert_Exists() public {
        tree.insert(account, validator);

        vm.expectRevert(abi.encodeWithSelector(Exists.selector, account));
        tree.insert(account, validator);
    }

    function testInsert(uint128[] memory amounts) public {
        uint256 stakesCount;
        uint256 totalStake;

        // insert in tree
        for (uint256 i; i < amounts.length; ++i) {
            address _account = vm.addr(i + 1);
            uint128 amount = amounts[i];
            Validator memory _validator;
            if (amount > 0) {
                _validator = _createValidator(amount);
                ++stakesCount;
            } else {
                // if amount is 0, set commission to i + 1,
                // so we can assert insertion
                _validator.commission = i + 1; // + 1 guarantees uniqueness
            }

            tree.insert(_account, _validator);
            totalStake += amount;

            // accounts with no stake
            if (amount == 0) {
                assertEq(tree.get(_account), _validator, "Accounts with no stake");
            }
        }
        vm.assume(stakesCount > 0);
        address _account = tree.first();
        address prevAccount;

        // tree balance
        assertNotEq(tree.stakeOf(_account), 0); // accounts with no stake should not be included
        while (tree.next(_account) != address(0)) {
            prevAccount = _account;
            _account = tree.next(_account);

            assertNotEq(tree.stakeOf(_account), 0);
            assertGe(tree.stakeOf(_account), tree.stakeOf(prevAccount), "Tree balance");
        }
        // validator count
        assertEq(tree.count, stakesCount, "Validator count");
        // total stake
        assertEq(tree.totalStake, totalStake, "Total stake");
    }
}

abstract contract NonEmptyState is EmptyState {
    using ValidatorStorageLib for ValidatorTree;

    // saved data for assertion
    address[] accounts;
    mapping(address => uint128) amountOf;
    address firstAccount;
    address lastAccount;

    function setUp() public virtual override {
        super.setUp();
    }

    /// @notice Populate tree with unique accounts
    /// @dev Use in fuzz tests
    function _populateTree(uint128[] memory amounts) internal {
        uint256 stakesCount;
        for (uint256 i; i < amounts.length; ) {
            address _account = vm.addr(i + 1);
            uint128 amount = amounts[i];
            Validator memory _validator = _createValidator(amount);
            accounts.push(_account);
            amountOf[_account] = amount;
            if (amount > 0) {
                ++stakesCount;
                // initialize saved data
                if (stakesCount == 1) {
                    firstAccount = _account;
                    lastAccount = _account;
                }
                // update saved data
                if (amount < amountOf[firstAccount]) firstAccount = _account;
                if (amount >= amountOf[lastAccount]) lastAccount = _account;
            }
            tree.insert(_account, _validator);

            unchecked {
                ++i;
            }
        }
        vm.assume(stakesCount > 0);
    }
}

contract ValidatorStorageTest_NonEmptyState is NonEmptyState {
    using ValidatorStorageLib for ValidatorTree;

    function testGet_EmptyValidator() public {
        Validator memory _validator;

        assertEq(tree.get(account), _validator);
    }

    function testGet(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];
            Validator memory _validator = _createValidator(amountOf[_account]);

            assertEq(tree.get(_account), _validator);
        }
    }

    /// @notice A simple getDelegationPool test
    /// @dev Update as neccessary in the future
    function testGetDelegationPool() public {
        tree.delegationPools[account].supply = 1; // // we set supply to 1 so we can assert retrieval

        assertEq(tree.getDelegationPool(account).supply, 1);
    }

    function testStakeOf(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];

            assertEq(tree.stakeOf(_account), amountOf[_account]);
        }
    }

    function testFirst(uint128[] memory amounts) public {
        _populateTree(amounts);

        assertEq(tree.first(), firstAccount);
    }

    function testLast(uint128[] memory amounts) public {
        _populateTree(amounts);

        assertEq(tree.last(), lastAccount);
    }

    function testCannotNext_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(AmountZero.selector));
        tree.next(address(0));
    }

    function testNext(uint128[] memory amounts) public {
        _populateTree(amounts);
        address prevAccount;
        address _account = firstAccount;

        while (tree.next(_account) != address(0)) {
            prevAccount = _account;
            _account = tree.next(_account);

            // stake and order
            assertEq(tree.stakeOf(_account), amountOf[_account], "Stake");
            assertGe(amountOf[_account], amountOf[prevAccount], "Stake order");
        }
        // end address
        assertEq(_account, lastAccount, "End address");
    }

    function testCannotPrev_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(AmountZero.selector));
        tree.prev(address(0));
    }

    function testPrev(uint128[] memory amounts) public {
        _populateTree(amounts);
        address nextAccount;
        account = lastAccount;

        while (tree.prev(account) != address(0)) {
            nextAccount = account;
            account = tree.prev(account);

            // stake and order
            assertEq(tree.stakeOf(account), amountOf[account], "Stake");
            assertLe(amountOf[account], amountOf[nextAccount], "Stake order");
        }
        // end address
        assertEq(account, firstAccount, "End address");
    }

    function testExists(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];

            if (amountOf[_account] > 0) assertTrue(tree.exists(_account), "Accounts with stake");
            else assertFalse(tree.exists(_account), "Accounts with no stake");
        }
    }

    function testIsEmpty() public {
        assertTrue(ValidatorStorageLib.isEmpty(address(0)), "Zero address");
        assertFalse(ValidatorStorageLib.isEmpty(account), "Non-zero address");
    }

    function testCannotGetNode_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, account));
        tree.getNode(account);
    }

    function testGetNode(uint128[] memory amounts, uint256 i) public {
        _populateTree(amounts);
        address accountToLookUp = accounts[i % accounts.length];
        vm.assume(amountOf[accountToLookUp] > 0);

        (address returnKey, address parent, address left, address right, bool red) = tree.getNode(accountToLookUp);
        Node memory node = Node(parent, left, right, red, _createValidator(amountOf[returnKey]));

        assertEq(node, tree.nodes[accountToLookUp]);
    }

    function testCannotRemove_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        tree.remove(address(0));
    }

    function testCannotRemove_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, account));
        tree.remove(account);
    }

    function testRemove(uint128[] memory amounts, uint256 i) public {
        _populateTree(amounts);
        address accountToRemove = accounts[i % accounts.length];
        vm.assume(amountOf[accountToRemove] > 0);
        // expected values
        uint256 stakesCount = tree.count - 1;
        uint256 totalStake = tree.totalStake - amountOf[accountToRemove];

        // remove from tree
        tree.remove(accountToRemove);

        address _account = tree.first();
        address prevAccount;
        // tree balance
        if (stakesCount > 0) {
            while (tree.next(_account) != address(0)) {
                prevAccount = _account;
                _account = tree.next(_account);

                assertGe(amountOf[_account], amountOf[prevAccount], "Tree balance");
            }
        }
        // validator count
        assertEq(tree.count, stakesCount, "Validator count");
        // total stake
        assertEq(tree.totalStake, totalStake, "Total stake");
    }

    function testRemove_All(uint128[] memory amounts) public {
        _populateTree(amounts);

        // remove from tree
        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];
            if (amountOf[_account] > 0) tree.remove(_account);
        }

        // no root
        assertEq(tree.root, address(0), "Root");
        // validator count
        assertEq(tree.count, 0, "Validator count");
        // total stake
        assertEq(tree.totalStake, 0, "Total stake");
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPERS
//////////////////////////////////////////////////////////////////////////*/

function _createValidator(uint256 amount) pure returns (Validator memory validator) {
    validator.stake = amount;
    validator.totalStake = amount;
}
