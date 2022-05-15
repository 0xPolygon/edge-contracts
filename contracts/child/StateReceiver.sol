// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {System} from "./System.sol";

// StateReceiver is the contract which executes and relays the state data on Polygon
contract StateReceiver is System {
    // Maxium gas state sync use
    uint256 public constant MAX_GAS = 300000;
    // Index of the next event which needs to be processed.
    uint256 public counter;

    // 0=success, 1=failure, 2=skip
    enum ResultStatus {
        SUCCESS,
        FAILURE,
        SKIP
    }

    event ResultEvent(
        uint256 indexed counter,
        ResultStatus indexed status,
        bytes extra
    );

    function stateSync(
        uint256 id,
        address sender,
        address receiver,
        bytes calldata data,
        bool skip,
        bytes calldata sigs
    ) public payable {
        // validate state id order
        require(counter + 1 == id, "ID_NOT_SEQUENTIAL");

        // increament the counter
        counter++;

        // create sig data for verification
        // data = hash(id, skip)
        bytes32 sigData = keccak256(abi.encode(id, skip));

        // verify signatures for provided sig data and sigs bytes
        bool sigVerfied = false;
        // solhint-disable-next-line avoid-low-level-calls
        (sigVerfied, ) = PRECOMPILED_SIGS_VERIFICATION_CONTRACT.call{
            value: 0,
            gas: PRECOMPILED_SIGS_VERIFICATION_CONTRACT_GAS
        }(abi.encode(sigData, sigs));
        require(sigVerfied, "SIG_VERIFICATION_FAILED");

        // Skip transaction if necessary
        if (skip) {
            emit ResultEvent(counter, ResultStatus.SKIP, "");
            return;
        }

        // Execute `onStateReceive` method on target using max gas limit
        bool success = false;
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint256,address,bytes)",
            counter,
            sender,
            data
        );
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = receiver.call{value: 0, gas: MAX_GAS}(paramData);

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            emit ResultEvent(counter, ResultStatus.SUCCESS, "");
        } else {
            emit ResultEvent(counter, ResultStatus.FAILURE, "");
        }
    }
}
