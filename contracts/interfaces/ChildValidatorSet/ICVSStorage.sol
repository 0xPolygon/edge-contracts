// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
