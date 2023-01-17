// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@utils/Test.sol";

import {ValidatorStorageLib, AmountZero, Exists, NotFound} from "contracts/libs/ValidatorStorage.sol";
import {RewardPool, Validator, Node, ValidatorTree} from "contracts/interfaces/IValidator.sol";

abstract contract EmptyState is Test {
    address account;
    Validator validator;

    ValidatorStorageLibUser validatorStorageLibUser;

    function setUp() public virtual {
        account = makeAddr("account");
        validator = _createValidator(1 ether);
        validatorStorageLibUser = new ValidatorStorageLibUser();
    }
}

contract ValidatorStorageTest_EmptyState is EmptyState {
    function testCannotInsert_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        validatorStorageLibUser.insert(address(0), validator);
    }

    function testCannotInsert_Exists() public {
        validatorStorageLibUser.insert(account, validator);

        vm.expectRevert(abi.encodeWithSelector(Exists.selector, account));
        validatorStorageLibUser.insert(account, validator);
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

            validatorStorageLibUser.insert(_account, _validator);
            totalStake += amount;

            // accounts with no stake
            if (amount == 0) {
                assertEq(validatorStorageLibUser.get(_account), _validator, "Accounts with no stake");
            }
        }
        vm.assume(stakesCount > 0);
        address _account = validatorStorageLibUser.first();
        address prevAccount;

        // tree balance
        assertNotEq(validatorStorageLibUser.stakeOf(_account), 0); // accounts with no stake should not be included
        while (validatorStorageLibUser.next(_account) != address(0)) {
            prevAccount = _account;
            _account = validatorStorageLibUser.next(_account);

            assertNotEq(validatorStorageLibUser.stakeOf(_account), 0);
            assertGe(
                validatorStorageLibUser.stakeOf(_account),
                validatorStorageLibUser.stakeOf(prevAccount),
                "Tree balance"
            );
        }
        // validator count
        assertEq(validatorStorageLibUser.countGetter(), stakesCount, "Validator count");
        // total stake
        assertEq(validatorStorageLibUser.totalStakeGetter(), totalStake, "Total stake");
    }
}

abstract contract NonEmptyState is EmptyState {
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
            validatorStorageLibUser.insert(_account, _validator);

            unchecked {
                ++i;
            }
        }
        vm.assume(stakesCount > 0);
    }
}

contract ValidatorStorageTest_NonEmptyState is NonEmptyState {
    function testGet_EmptyValidator() public {
        Validator memory _validator;

        assertEq(validatorStorageLibUser.get(account), _validator);
    }

    function testGet(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];
            Validator memory _validator = _createValidator(amountOf[_account]);

            assertEq(validatorStorageLibUser.get(_account), _validator);
        }
    }

    /// @notice A simple getDelegationPool test
    /// @dev Update as neccessary in the future
    function testGetDelegationPool() public {
        assertEq(validatorStorageLibUser.getDelegationPool_Supply(address(1337)), 1337);
    }

    function testStakeOf(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];

            assertEq(validatorStorageLibUser.stakeOf(_account), amountOf[_account]);
        }
    }

    function testFirst(uint128[] memory amounts) public {
        _populateTree(amounts);

        assertEq(validatorStorageLibUser.first(), firstAccount);
    }

    function testLast(uint128[] memory amounts) public {
        _populateTree(amounts);

        assertEq(validatorStorageLibUser.last(), lastAccount);
    }

    function testCannotNext_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(AmountZero.selector));
        validatorStorageLibUser.next(address(0));
    }

    function testNext(uint128[] memory amounts) public {
        _populateTree(amounts);
        address prevAccount;
        address _account = firstAccount;

        while (validatorStorageLibUser.next(_account) != address(0)) {
            prevAccount = _account;
            _account = validatorStorageLibUser.next(_account);

            // stake and order
            assertEq(validatorStorageLibUser.stakeOf(_account), amountOf[_account], "Stake");
            assertGe(amountOf[_account], amountOf[prevAccount], "Stake order");
        }
        // end address
        assertEq(_account, lastAccount, "End address");
    }

    function testCannotPrev_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(AmountZero.selector));
        validatorStorageLibUser.prev(address(0));
    }

    function testPrev(uint128[] memory amounts) public {
        _populateTree(amounts);
        address nextAccount;
        account = lastAccount;

        while (validatorStorageLibUser.prev(account) != address(0)) {
            nextAccount = account;
            account = validatorStorageLibUser.prev(account);

            // stake and order
            assertEq(validatorStorageLibUser.stakeOf(account), amountOf[account], "Stake");
            assertLe(amountOf[account], amountOf[nextAccount], "Stake order");
        }
        // end address
        assertEq(account, firstAccount, "End address");
    }

    function testExists(uint128[] memory amounts) public {
        _populateTree(amounts);

        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];

            if (amountOf[_account] > 0) assertTrue(validatorStorageLibUser.exists(_account), "Accounts with stake");
            else assertFalse(validatorStorageLibUser.exists(_account), "Accounts with no stake");
        }
    }

    function testIsEmpty() public {
        assertTrue(validatorStorageLibUser.isEmpty(address(0)), "Zero address");
        assertFalse(validatorStorageLibUser.isEmpty(account), "Non-zero address");
    }

    function testCannotGetNode_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, account));
        validatorStorageLibUser.getNode(account);
    }

    function testGetNode(uint128[] memory amounts, uint256 i) public {
        _populateTree(amounts);
        address accountToLookUp = accounts[i % accounts.length];
        vm.assume(amountOf[accountToLookUp] > 0);

        (address returnKey, address parent, address left, address right, bool red) = validatorStorageLibUser.getNode(
            accountToLookUp
        );
        Node memory node = Node(parent, left, right, red, _createValidator(amountOf[returnKey]));

        assertEq(node, validatorStorageLibUser.nodesGetter(accountToLookUp));
    }

    function testCannotRemove_ZeroAddress() public {
        vm.expectRevert(stdError.assertionError);
        validatorStorageLibUser.remove(address(0));
    }

    function testCannotRemove_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector, account));
        validatorStorageLibUser.remove(account);
    }

    function testRemove(uint128[] memory amounts, uint256 i) public {
        _populateTree(amounts);
        address accountToRemove = accounts[i % accounts.length];
        vm.assume(amountOf[accountToRemove] > 0);
        // expected values
        uint256 stakesCount = validatorStorageLibUser.countGetter() - 1;
        uint256 totalStake = validatorStorageLibUser.totalStakeGetter() - amountOf[accountToRemove];

        // remove from tree
        validatorStorageLibUser.remove(accountToRemove);

        address _account = validatorStorageLibUser.first();
        address prevAccount;
        // tree balance
        if (stakesCount > 0) {
            while (validatorStorageLibUser.next(_account) != address(0)) {
                prevAccount = _account;
                _account = validatorStorageLibUser.next(_account);

                assertGe(amountOf[_account], amountOf[prevAccount], "Tree balance");
            }
        }
        // validator count
        assertEq(validatorStorageLibUser.countGetter(), stakesCount, "Validator count");
        // total stake
        assertEq(validatorStorageLibUser.totalStakeGetter(), totalStake, "Total stake");
    }

    function testRemove_All(uint128[] memory amounts) public {
        _populateTree(amounts);

        // remove from tree
        for (uint256 i; i < accounts.length; ++i) {
            address _account = accounts[i];
            if (amountOf[_account] > 0) validatorStorageLibUser.remove(_account);
        }

        // no root
        assertEq(validatorStorageLibUser.rootGetter(), address(0), "Root");
        // validator count
        assertEq(validatorStorageLibUser.countGetter(), 0, "Validator count");
        // total stake
        assertEq(validatorStorageLibUser.totalStakeGetter(), 0, "Total stake");
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPERS
//////////////////////////////////////////////////////////////////////////*/

function _createValidator(uint256 amount) pure returns (Validator memory validator) {
    validator.stake = amount;
}

/*//////////////////////////////////////////////////////////////////////////
                                MOCKS
//////////////////////////////////////////////////////////////////////////*/

contract ValidatorStorageLibUser {
    ValidatorTree tree;

    constructor() {
        tree.delegationPools[address(1337)].supply = 1337;
    }

    function get(address validator) external view returns (Validator memory) {
        Validator memory r = ValidatorStorageLib.get(tree, validator);
        return r;
    }

    /// @dev RewardPool cannot be returned because it contains mappings;
    /// @dev instead we return its supply, which is enough for testing purposes currently
    function getDelegationPool_Supply(address validator) external view returns (uint256) {
        uint256 r_supply = ValidatorStorageLib.getDelegationPool(tree, validator).supply;
        return r_supply;
    }

    function stakeOf(address account) external view returns (uint256) {
        uint256 r = ValidatorStorageLib.stakeOf(tree, account);
        return r;
    }

    function first() external view returns (address) {
        address r = ValidatorStorageLib.first(tree);
        return r;
    }

    function last() external view returns (address) {
        address r = ValidatorStorageLib.last(tree);
        return r;
    }

    function next(address target) external view returns (address) {
        address r = ValidatorStorageLib.next(tree, target);
        return r;
    }

    function prev(address target) external view returns (address) {
        address r = ValidatorStorageLib.prev(tree, target);
        return r;
    }

    function exists(address key) external view returns (bool) {
        bool r = ValidatorStorageLib.exists(tree, key);
        return r;
    }

    function isEmpty(address key) external pure returns (bool) {
        bool r = ValidatorStorageLib.isEmpty(key);
        return r;
    }

    function getNode(address key) external view returns (address, address, address, address, bool) {
        (address a, address b, address c, address d, bool e) = ValidatorStorageLib.getNode(tree, key);
        return (a, b, c, d, e);
    }

    function insert(address key, Validator memory validator) external {
        ValidatorStorageLib.insert(tree, key, validator);
    }

    function remove(address key) external {
        ValidatorStorageLib.remove(tree, key);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        GETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function rootGetter() external view returns (address) {
        return tree.root;
    }

    function countGetter() external view returns (uint256) {
        return tree.count;
    }

    function totalStakeGetter() external view returns (uint256) {
        return tree.totalStake;
    }

    function nodesGetter(address a) external view returns (Node memory) {
        return tree.nodes[a];
    }
}
