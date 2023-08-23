// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract StakeManagerLegacyCompatStorage {
    // StakeManager

    IERC20 internal stakingToken;

    // StakeManagerChildData

    // Highest child chain id allocated thus far. Child chain id 0x00 is an invalid id.
    uint256 internal counter;
    // child chain id to child chain manager contract address.
    // slither-disable-next-line naming-convention
    mapping(uint256 => address) internal __managers;
    // child chain manager contract address to child chain id.
    // slither-disable-next-line naming-convention
    mapping(address => uint256) internal _ids;

    // StakeManagerStakingData

    // slither-disable-next-line naming-convention
    uint256 internal _totalStake;
    // validator => child => amount
    // slither-disable-next-line naming-convention
    mapping(address => mapping(uint256 => uint256)) internal __stakes;
    // child chain id => total stake
    // slither-disable-next-line naming-convention
    mapping(uint256 => uint256) internal __totalStakePerChild;
    // validator address => stake across all child chains.
    // slither-disable-next-line naming-convention
    mapping(address => uint256) internal __totalStakes;
    // validator address => withdrawable stake.
    // slither-disable-next-line naming-convention
    mapping(address => uint256) internal __withdrawableStakes;

    // Storage gaps

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __StakeManagerChildData_gap;

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __StakeManagerStakingData_gap;
}
