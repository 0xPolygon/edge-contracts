// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../IValidator.sol";

struct UptimeData {
    address validator;
    uint256 signedBlocks;
}

struct Uptime {
    uint256 epochId;
    UptimeData[] uptimeData;
    uint256 totalBlocks;
}

struct Epoch {
    uint256 startBlock;
    uint256 endBlock;
    bytes32 epochRoot;
}

interface ICVSStorage {
    /**
     * @notice Gets validator by address.
     * @return blsKey BLS public key
     * @return stake self-stake
     * @return totalStake self-stake + delegation
     * @return commission
     * @return withdrawableRewards withdrawable rewards
     * @return active activity status
     */
    function getValidator(
        address validator
    )
        external
        view
        returns (
            uint256[4] memory blsKey,
            uint256 stake,
            uint256 totalStake,
            uint256 commission,
            uint256 withdrawableRewards,
            bool active
        );
}
