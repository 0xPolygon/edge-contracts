// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ValidatorStorageLib} from "contracts/libs/ValidatorStorage.sol";
import "contracts/interfaces/IValidator.sol";

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
            // if amount is 0, set commission to i + 1,
            // so we can check if it was inserted
            if (amount == 0) {
                _validator.commission = i + 1; // + 1 guarantees uniqueness
            } else {
                _validator = _createValidator(amount);
            }
            if (amount > 0) ++stakesCount;
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

    function testStakeOf(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            account = accounts[i];

            assertEq(tree.stakeOf(account), amountOf[account]);
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
        account = firstAccount;

        while (tree.next(account) != address(0)) {
            prevAccount = account;
            account = tree.next(account);

            // assert address by first checking stake, then order
            assertEq(tree.stakeOf(account), amountOf[account], "Stake");
            assertGe(amountOf[account], amountOf[prevAccount], "Stake order");
        }
        // last address
        assertEq(account, lastAccount, "Last address");
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

            // assert address by first checking stake, then order
            assertEq(tree.stakeOf(account), amountOf[account]);
            assertLe(amountOf[account], amountOf[nextAccount]);
        }
        // last address
        assertEq(account, firstAccount);
    }

    function testExists(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            account = accounts[i];

            if (amountOf[account] > 0) assertTrue(tree.exists(account), "Accounts with stake");
            else assertFalse(tree.exists(account), "Accounts with no stake");
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

    // TODO
    function testGetNode() public {
        require(false, "Test not written");
    }

    function testCannotRemove_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        tree.remove(address(0));
    }

    function testCannotRemove_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, account));
        tree.remove(account);
    }

    // TODO Remove only one validator to speed up test
    function testRemove(uint128[] memory amounts) public {
        _populateTree(amounts);
        uint256 stakesCount = tree.count;
        uint256 totalStake = tree.totalStake;

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];
            if (amountOf[_account] != 0) {
                // modify expected values
                --stakesCount;
                totalStake -= amountOf[_account];

                // remove from tree
                tree.remove(_account);
            }

            address __account = tree.first();
            address prevAccount;

            // tree balance
            if (stakesCount > 0) {
                while (tree.next(__account) != address(0)) {
                    prevAccount = __account;
                    __account = tree.next(__account);

                    assertGe(amountOf[__account], amountOf[prevAccount], "Tree balance");
                }
            }
            // validator count
            assertEq(tree.count, stakesCount, "Validator count");
            // total stake
            assertEq(tree.totalStake, totalStake, "Total stake");
        }
    }

    /// @notice Populate tree with unique accounts
    /// @dev Use in fuzz tests
    function _populateTree(uint128[] memory amounts) internal {
        uint256 stakesCount;
        for (uint256 i; i < amounts.length; ) {
            address _account = vm.addr(i + 1);
            console.log(_account);
            uint128 amount = amounts[i];
            Validator memory _validator = _createValidator(amount);
            accounts.push(_account);
            amountOf[_account] = amount;
            if (amount > 0) ++stakesCount;
            if (amount != 0) {
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

/*//////////////////////////////////////////////////////////////////////////
                                HELPERS
//////////////////////////////////////////////////////////////////////////*/

function _createValidator(uint256 amount) returns (Validator memory validator) {
    validator.stake = amount;
    validator.totalStake = amount;
}
