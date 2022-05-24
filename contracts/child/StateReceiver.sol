// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {System} from "./System.sol";

// StateReceiver is the contract which executes and relays the state data on Polygon
contract StateReceiver is System {
    struct StateSync {
        uint256 id;
        address sender;
        address receiver;
        bytes data;
        bool skip;
    }
    // Maximum gas provided for each message call
    // slither-disable-next-line too-many-digits
    uint256 public constant MAX_GAS = 300000;
    // Index of the next event which needs to be processed
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public counter;

    // 0=success, 1=failure, 2=skip
    enum ResultStatus {
        SUCCESS,
        FAILURE,
        SKIP
    }

    event StateSyncResult(
        uint256 indexed counter,
        ResultStatus indexed status,
        bytes message
    );

    function stateSync(StateSync calldata obj, bytes calldata signature)
        external
        onlySystemCall
    {
        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(abi.encode(obj));

        _checkPubkeyAggregation(dataHash, signature);

        // execute state sync
        _executeStateSync(counter++, obj);
    }

    function stateSyncBatch(StateSync[] calldata objs, bytes calldata signature)
        external
        onlySystemCall
    {
        require(objs.length != 0, "NO_STATESYNC_DATA");

        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(abi.encode(objs));

        _checkPubkeyAggregation(dataHash, signature);

        uint256 currentId = counter;
        for (uint256 index = 0; index < objs.length; index++) {
            _executeStateSync(currentId++, objs[index]);
        }
        counter = currentId;
    }

    //
    // Execute state sync
    //

    function _executeStateSync(uint256 prevId, StateSync calldata obj)
        internal
    {
        require(prevId + 1 == obj.id, "ID_NOT_SEQUENTIAL");

        // Skip transaction if necessary
        if (obj.skip) {
            emit StateSyncResult(obj.id, ResultStatus.SKIP, "");
            return;
        }

        // Execute `onStateReceive` method on target using max gas limit
        bool success = false;
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint256,address,bytes)",
            obj.id,
            obj.sender,
            obj.data
        );

        // if EOA, skip call
        if (obj.receiver.code.length != 0) {
            // this is not reentrant because of our system call modifier
            // slither-disable-next-line calls-loop,low-level-calls
            (success, ) = obj.receiver.call{gas: MAX_GAS}(paramData); // solhint-disable-line avoid-low-level-calls
        } else {
            emit StateSyncResult(obj.id, ResultStatus.SKIP, "");
            return;
        }

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.SUCCESS, "");
        } else {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.FAILURE, "");
        }
    }

    function _checkPubkeyAggregation(bytes32 message, bytes calldata signature)
        internal
        view
    {
        // verify signatures` for provided sig data and sigs bytes
        // solhint-disable-next-line avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (
            bool callSuccess,
            bytes memory returnData
        ) = VALIDATOR_PKCHECK_PRECOMPILE.staticcall{
                gas: VALIDATOR_PKCHECK_PRECOMPILE_GAS
            }(abi.encode(message, signature));
        bool verified = abi.decode(returnData, (bool));
        require(callSuccess && verified, "SIGNATURE_VERIFICATION_FAILED");
    }
}
