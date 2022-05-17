// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {System} from "./System.sol";

// StateReceiver is the contract which executes and relays the state data on Polygon
contract StateReceiver is ReentrancyGuard, System {
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

    struct StateSync {
        uint256 id;
        address sender;
        address receiver;
        bytes data;
        bool result;
    }

    function stateSync(StateSync calldata obj, bytes calldata sigs)
        external
        nonReentrant
    {
        // validate state id order
        require(counter + 1 == obj.id, "ID_NOT_SEQUENTIAL");
        // check sender
        require(obj.sender != address(0), "INVALID_SENDER");
        // check receiver
        require(obj.receiver != address(0), "INVALID_RECEIVER");

        // increament the counter
        counter++;

        // create sig data for verification
        // counter, sender, receiver, data and result should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(
            abi.encode(obj.id, obj.sender, obj.receiver, obj.data, obj.result)
        );

        // verify signatures` for provided sig data and sigs bytes
        bool sigVerfied = false;
        // solhint-disable-next-line avoid-low-level-calls
        (sigVerfied, ) = PRECOMPILED_SIGS_VERIFICATION_CONTRACT.call{
            gas: PRECOMPILED_SIGS_VERIFICATION_CONTRACT_GAS
        }(abi.encode(dataHash, sigs));
        require(sigVerfied, "SIG_VERIFICATION_FAILED");

        // Skip transaction if necessary
        if (obj.result) {
            emit ResultEvent(counter, ResultStatus.SKIP, "");
            return;
        }

        // Execute `onStateReceive` method on target using max gas limit
        bool success = false;
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint256,address,bytes)",
            counter,
            obj.sender,
            obj.data
        );
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = obj.receiver.call{gas: MAX_GAS}(paramData);

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            emit ResultEvent(counter, ResultStatus.SUCCESS, "");
        } else {
            emit ResultEvent(counter, ResultStatus.FAILURE, "");
        }
    }
}
