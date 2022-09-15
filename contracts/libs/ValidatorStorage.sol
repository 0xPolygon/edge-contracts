// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IValidator.sol";
import "./RewardPool.sol";

error AmountZero();
error NotFound(address validator);
error Exists(address validator);

/**
 * @title Validator Storage Lib
 * @author Polygon Technology (Daniel Gretzke @gretzke)
 * @notice implementation of red-black ordered tree to order validators by stake
 * 
 * for more information on red-black trees: 
 * https://en.wikipedia.org/wiki/Red%E2%80%93black_tree
 * implementation draws on Rob Hutchins's (B9Labs) Order Statistics tree:
 * https://github.com/rob-Hitchens/OrderStatisticsTree
 * which in turn is based on BokkyPooBah's implementation
 * https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
 */
library ValidatorStorageLib {
    address private constant EMPTY = address(0);

    /**
     * @notice returns the Validator struct of a specific validator
     * @param self the ValidatorTree struct
     * @param validator the address of the validator to lookup
     * @return Validator struct
     */
    function get(ValidatorTree storage self, address validator) internal view returns (Validator storage) {
        // return empty validator object if validator doesn't exist
        return self.nodes[validator].validator;
    }

    /**
     * @notice returns RewardPool struct for a specific validator
     * @param self the ValidatorTree struct
     * @param validator the address of the validator whose pool is being queried
     * @return RewardPool struct for the validator
     */
    function getDelegationPool(ValidatorTree storage self, address validator)
        internal
        view
        returns (RewardPool storage)
    {
        return self.delegationPools[validator];
    }

    /**
     * @notice returns the stake of a specific validator
     * @param self the ValidatorTree struct
     * @param account the address of the validator to query the stake of
     * @return balance the stake of the validator (uint256)
     */
    function stakeOf(ValidatorTree storage self, address account) internal view returns (uint256 balance) {
        balance = self.nodes[account].validator.stake;
    }

    /**
     * @notice returns the address of the first validator in the tree
     * @param self the ValidatorTree struct
     * @return _key the address of the validator
     */
    function first(ValidatorTree storage self) internal view returns (address _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }

    /**
     * @notice returns the address of the last validator in the tree
     * @param self the ValidatorTree struct
     * @return _key the address of the validator
     */
    function last(ValidatorTree storage self) internal view returns (address _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }

    /**
     * @notice returns the next addr in the tree from a particular addr
     * @param self the ValidatorTree struct
     * @param target the address to check the next validator to
     * @return cursor the next validator's address
     */
    // slither-disable-next-line dead-code
    function next(ValidatorTree storage self, address target) internal view returns (address cursor) {
        if (target == EMPTY) revert AmountZero();
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /**
     * @notice returns the prev addr in the tree from a particular addr
     * @param self the ValidatorTree struct
     * @param target the address to check the previous validator to
     * @return cursor the previous validator's address
     */
    function prev(ValidatorTree storage self, address target) internal view returns (address cursor) {
        if (target == EMPTY) revert AmountZero();
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    /**
     * @notice checks membership of a specific address
     * @param self the ValidatorTree struct
     * @param key the address to check membership of
     * @return bool indicating if the address is in the tree or not
     */
    function exists(ValidatorTree storage self, address key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    /**
     * @notice checks if an address is the zero address
     * @param key the address to check
     * @return bool indicating if the address is the zero addr or not
     */
    // slither-disable-next-line dead-code
    function isEmpty(address key) internal pure returns (bool) {
        return key == EMPTY;
    }

    /**
     * @notice returns the tree positioning of an address in the tree
     * @param self the ValidatorTree struct
     * @param key the address to unpack the Validator struct of
     * @return _returnKey the address input as an argument
     * @return _parent the parent address in the node
     * @return _left the address to the left in the tree
     * @return _right the address to the right in the tree
     * @return _red if the node is red or not
     */
    // slither-disable-next-line dead-code
    function getNode(ValidatorTree storage self, address key)
        internal
        view
        returns (
            address _returnKey,
            address _parent,
            address _left,
            address _right,
            bool _red
        )
    {
        if (!exists(self, key)) revert NotFound(key);
        return (key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    /**
     * @notice inserts a validator into the tree
     * @param self the ValidatorTree struct
     * @param key the address to add
     * @param validator the Validator struct of the address
     */
    function insert(
        ValidatorTree storage self,
        address key,
        Validator memory validator
    ) internal {
        assert(key != EMPTY);
        assert(validator.totalStake >= validator.stake);
        if (exists(self, key)) revert Exists(key);
        if (validator.stake == 0) {
            self.nodes[key].validator = validator;
            return;
        }
        address cursor = EMPTY;
        address probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (validator.totalStake < self.nodes[probe].validator.totalStake) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true, validator: validator});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (validator.totalStake < self.nodes[cursor].validator.totalStake) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
        self.count++;
        self.totalStake += validator.stake;
    }

    /**
     * @notice removes a validator from the tree
     * @param self the ValidatorTree struct
     * @param key the address to remove
     */
    function remove(ValidatorTree storage self, address key) internal {
        assert(key != EMPTY);
        if (!exists(self, key)) revert NotFound(key);
        address probe;
        address cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        address yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        self.nodes[cursor].parent = EMPTY;
        self.nodes[cursor].left = EMPTY;
        self.nodes[cursor].right = EMPTY;
        self.nodes[cursor].red = false;
        self.count--;
        self.totalStake -= self.nodes[cursor].validator.stake;
    }

    /**
     * @notice returns the left-most node from an address in the tree
     * @param self the ValidatorTree struct
     * @param key the address to check the left-most node from
     * @return address the left-most node from the input address
     */
    // slither-disable-next-line dead-code
    function treeMinimum(ValidatorTree storage self, address key) private view returns (address) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    /**
     * @notice returns the right-most node from an address in the tree
     * @param self the ValidatorTree struct
     * @param key the address to check the right-most node from
     * @return address the right-most node from the input address
     */
    function treeMaximum(ValidatorTree storage self, address key) private view returns (address) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return (key);
    }

    /**
     * @notice moves a validator to the left in the tree
     * @param self the ValidatorTree struct
     * @param key the address to move to the left
     */
    function rotateLeft(ValidatorTree storage self, address key) private {
        address cursor = self.nodes[key].right;
        address keyParent = self.nodes[key].parent;
        address cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }

    /**
     * @notice moves a validator to the right in the tree
     * @param self the ValidatorTree struct
     * @param key the address to move to the right
     */
    function rotateRight(ValidatorTree storage self, address key) private {
        address cursor = self.nodes[key].left;
        address keyParent = self.nodes[key].parent;
        address cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    /**
     * @notice private function for repainting tree on insert
     * @param self the ValidatorTree struct
     * @param key the address being inserted into the tree
     */
    function insertFixup(ValidatorTree storage self, address key) private {
        address cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            address keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    /**
     * @notice changes the parent node of a validator's node in the tree
     * @param self the ValidatorTree struct
     * @param a the address to have the parent changed
     * @param b the parent will be changed to the parent of this addr
     */
    function replaceParent(
        ValidatorTree storage self,
        address a,
        address b
    ) private {
        address bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    /**
     * @notice private function for repainting tree on remove
     * @param self the ValidatorTree struct
     * @param key the address being removed into the tree
     */
    function removeFixup(ValidatorTree storage self, address key) private {
        address cursor;
        while (key != self.root && !self.nodes[key].red) {
            address keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
