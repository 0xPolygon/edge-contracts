// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface RewardToken {
    function mintRewards(uint256 amount) external;
}

contract MockRewardToken is ERC20 {
    constructor() ERC20("Mock Reward Token", "RWD") {}

    function mintRewards(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
