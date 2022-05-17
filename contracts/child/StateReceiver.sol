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
        bool skip;
    }

    function stateSync(StateSync calldata obj, bytes calldata sigs)
        external
        nonReentrant
    {
        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(
            abi.encode(obj.id, obj.sender, obj.receiver, obj.data, obj.skip)
        );

        // verify signatures` for provided sig data and sigs bytes
        bool success = false;
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = PRECOMPILED_SIGS_VERIFICATION_CONTRACT.staticcall{
            gas: PRECOMPILED_SIGS_VERIFICATION_CONTRACT_GAS
        }(abi.encode(dataHash, sigs));
        require(success, "SIG_VERIFICATION_FAILED");

        // execute state sync
        _executeStateSync(counter, obj);
    }

    function stateSyncBatch(StateSync[] calldata objs, bytes calldata sigs)
        external
        nonReentrant
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
            StateSync calldata obj = objs[index];

            _executeStateSync(currentId++, obj);
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
            emit ResultEvent(counter, ResultStatus.SKIP, "");
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
            emit ResultEvent(counter, ResultStatus.SKIP, "");
            return;
        }

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            emit ResultEvent(counter, ResultStatus.SUCCESS, "");
        } else {
            emit ResultEvent(counter, ResultStatus.FAILURE, "");
        }
    }
}
