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
    uint256 public constant MAX_GAS = 300000;
    // Index of the next event which needs to be processed
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

    function stateSync(StateSync calldata obj, bytes calldata sigs)
        external
        onlySystemCall
    {
        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(abi.encode(obj));

        // verify signatures` for provided sig data and sigs bytes
        bool success = false;
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = PRECOMPILED_SIGS_VERIFICATION_CONTRACT.staticcall{
            gas: PRECOMPILED_SIGS_VERIFICATION_CONTRACT_GAS
        }(abi.encode(dataHash, sigs));
        require(success, "SIG_VERIFICATION_FAILED");

        // execute state sync
        _executeStateSync(counter++, obj);
    }

    function stateSyncBatch(StateSync[] calldata objs, bytes calldata sigs)
        external
        onlySystemCall
    {
        require(objs.length != 0, "NO_STATESYNC_DATA");

        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)

        // verify signatures` for provided sig data and sigs bytes
        bool success = false;
        bytes32 dataHash = keccak256(abi.encode(objs));
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = PRECOMPILED_SIGS_VERIFICATION_CONTRACT.staticcall{
            gas: PRECOMPILED_SIGS_VERIFICATION_CONTRACT_GAS
        }(abi.encode(dataHash, sigs));
        require(success, "SIG_VERIFICATION_FAILED");

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
            emit StateSyncResult(counter, ResultStatus.SKIP, "");
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

        if (obj.receiver.code.length != 0) {
            // if EOA, skip call
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = obj.receiver.call{gas: MAX_GAS}(paramData);
        } else {
            emit StateSyncResult(counter, ResultStatus.SKIP, "");
            return;
        }

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            emit StateSyncResult(counter, ResultStatus.SUCCESS, "");
        } else {
            emit StateSyncResult(counter, ResultStatus.FAILURE, "");
        }
    }
}
