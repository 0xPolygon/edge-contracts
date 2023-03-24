// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../IStateReceiver.sol";
import "../../../child/modules/CVSWithdrawal.sol";

struct ValidatorInit {
    address addr;
    uint256 stake;
}

interface IValidatorSet is IStateReceiver {
    function EPOCH_SIZE() external view returns (uint256);

    function totalBlocks(uint256 epochId) external view returns (uint256 length);

    function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256);

    function totalSupplyAt(uint256 epochNumber) external view returns (uint256);

    function commitEpoch(uint256 id, Epoch calldata epoch) external;

    function unstake(uint256 amount) external;

    function withdraw() external;
}
