// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {System} from "./System.sol";
import {Merkle} from "../common/Merkle.sol";

/**
 * @title State Receiver
 * @author Polygon Technology (JD Kanani @jdkanani, @QEDK)
 * @notice executes and relays the state data on the child chain
 */
contract StateReceiver is System {
    using Merkle for bytes32;

    struct StateSync {
        uint256 id;
        address sender;
        address receiver;
        bytes data;
        bool skip;
    }

    struct StateSyncBundle {
        uint256 startId;
        uint256 endId;
        uint256 leaves;
        bytes32 root;
    }
    // Maximum gas provided for each message call
    // slither-disable-next-line too-many-digits
    uint256 public constant MAX_GAS = 300000;
    // Index of the next event which needs to be processed
    uint256 public counter;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public bundleCounter = 1;
    uint256 public lastExecutedBundleCounter = 1;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public lastCommittedId;
    uint256 public currentLeafIndex;

    mapping(uint256 => StateSyncBundle) public bundles;

    // 0=success, 1=failure, 2=skip
    enum ResultStatus {
        SUCCESS,
        FAILURE,
        SKIP
    }

    event StateSyncResult(uint256 indexed counter, ResultStatus indexed status, bytes32 message);

    /**
     * @notice commits merkle root of multiple StateSync objects
     * @param bundle StateSync struct with root to be committed
     * @param signature bundle signed (by BLS)
     * @param bitmap bitmap of which validators signed the message
     */
    function commit(
        StateSyncBundle calldata bundle, 
        bytes calldata signature,
        bytes calldata bitmap
    ) external onlySystemCall {
        uint256 currentBundleCounter = bundleCounter++;
        require(bundle.startId == lastCommittedId + 1, "INVALID_START_ID");
        require(bundle.endId >= bundle.startId, "INVALID_END_ID");
        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(abi.encode(bundle));

        _checkPubkeyAggregation(dataHash, signature, bitmap);

        bundles[currentBundleCounter] = bundle;

        lastCommittedId = bundle.endId;
    }

    /**
     * @notice submits leaf of tree of root data for execution
     * @dev function does not have to be called from client
     * and can be called arbitrarily so long as proper data/proofs are supplied
     * @param proof array of merkle proofs
     * @param objs array of StateSync objects being proven (the keccak of which is the leaf)
     */
    function execute(bytes32[] calldata proof, StateSync[] calldata objs) external {
        require(lastExecutedBundleCounter < bundleCounter, "NOTHING_TO_EXECUTE");

        bytes32 dataHash = keccak256(abi.encode(objs));

        StateSyncBundle memory bundle = bundles[lastExecutedBundleCounter];

        uint256 leafIndex = currentLeafIndex;

        require(dataHash.checkMembership(leafIndex++, bundle.root, proof), "INVALID_PROOF");

        if (leafIndex == bundle.leaves) {
            currentLeafIndex = 0;
            delete bundles[lastExecutedBundleCounter++];
        } else {
            currentLeafIndex++;
        }

        uint256 currentId = counter;
        uint256 length = objs.length;
        counter += objs.length;

        // execute state sync
        for (uint256 i = 0; i < length; ++i) {
            _executeStateSync(currentId++, objs[i]);
        }
    }

    /**
     * @notice internal function to execute StateSync objects received by StateReceiver
     * @param prevId id of last executed StateSync object
     * @param obj StateSync object to be executed
     */
    function _executeStateSync(uint256 prevId, StateSync calldata obj) internal {
        require(prevId + 1 == obj.id, "ID_NOT_SEQUENTIAL");

        // Skip transaction if client has added flag, or receiver has no code
        if (obj.skip || obj.receiver.code.length == 0) {
            emit StateSyncResult(obj.id, ResultStatus.SKIP, "");
            return;
        }

        // Execute `onStateReceive` method on target using max gas limit
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint256,address,bytes)",
            obj.id,
            obj.sender,
            obj.data
        );

        // slither-disable-next-line calls-loop,low-level-calls
        (bool success, bytes memory returnData) = obj.receiver.call{gas: MAX_GAS}(paramData); // solhint-disable-line avoid-low-level-calls

        bytes32 message = bytes32(returnData);

        // emit a ResultEvent indicating whether invocation of state sync was successful or not
        if (success) {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.SUCCESS, message);
        } else {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.FAILURE, message);
        }
    }

    /**
     * @notice verifies an aggregated BLS signature using BLS precompile
     * @param message plaintext of signed message
     * @param signature the signed message
     * @param bitmap bitmap of which validators have signed
     */
    function _checkPubkeyAggregation(
        bytes32 message, 
        bytes calldata signature,
        bytes calldata bitmap
    ) internal view {
        // verify signatures` for provided sig data and sigs bytes
        // solhint-disable-next-line avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool callSuccess, bytes memory returnData) = VALIDATOR_PKCHECK_PRECOMPILE.staticcall{
            gas: VALIDATOR_PKCHECK_PRECOMPILE_GAS
        }(abi.encode(message, signature, bitmap));
        bool verified = abi.decode(returnData, (bool));
        require(callSuccess && verified, "SIGNATURE_VERIFICATION_FAILED");
    }
}
