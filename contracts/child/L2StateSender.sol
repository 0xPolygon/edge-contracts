// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IStateSender.sol";

/**
    @title L2StateSender
    @author Polygon Technology (@QEDK)
    @notice Arbitrary message passing contract from L2 -> L1
    @dev There is no transaction execution on L1, only a commitment of the emitted events are stored
 */
contract L2StateSender is IStateSender {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;

    event L2StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    /**
     * @notice Emits an event which is indexed by v3 validators and submitted as a commitment on L1
     * allowing for lazy execution
     * @param receiver Address of the message recipient on L1
     * @param data Data to use in message call to recipient
     */
    function syncState(address receiver, bytes calldata data) external {
        // check receiver
        require(receiver != address(0), "INVALID_RECEIVER");
        // check data length
        require(data.length <= MAX_LENGTH, "EXCEEDS_MAX_LENGTH");

        emit L2StateSynced(++counter, msg.sender, receiver, data);
    }
}
