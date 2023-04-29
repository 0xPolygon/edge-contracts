// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct ChildChains {
    uint256 counter;
    mapping(uint256 => address) managers;
    mapping(address => uint256) ids;
}

library ChildManagerLib {
    function registerChild(ChildChains storage self, address manager) internal returns (uint256 id) {
        assert(manager != address(0));
        id = ++self.counter;
        self.managers[id] = manager;
        self.ids[manager] = id;
    }

    function managerOf(ChildChains storage self, uint256 id) internal view returns (address manager) {
        manager = self.managers[id];
        require(manager != address(0), "Invalid id");
    }

    function idFor(ChildChains storage self, address manager) internal view returns (uint256 id) {
        id = self.ids[manager];
        require(id != 0, "Invalid manager");
    }
}
