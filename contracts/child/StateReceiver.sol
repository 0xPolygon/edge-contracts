// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import {System} from "./System.sol";
import {Merkle} from "../common/Merkle.sol";

/**
 * @title State Receiver
 * @author Polygon Technology (JD Kanani @jdkanani, @QEDK)
 * @notice executes and relays the state data on the child chain
 */
contract StateReceiver is System {
    using ArraysUpgradeable for uint256[];
    using Merkle for bytes32;

    struct StateSync {
        uint256 id;
        address sender;
        address receiver;
        bytes data;
    }

    struct StateSyncBundle {
        uint256 startId;
        uint256 endId;
        bytes32 root;
    }

    /// @custom:security write-protection="onlySystemCall()"
    uint256 public bundleCounter;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public lastCommittedId;
    // Maximum gas provided for each message call
    // slither-disable-next-line too-many-digits
    uint256 private constant MAX_GAS = 300000;

    mapping(uint256 => StateSyncBundle) public bundles;
    uint256[] public stateSyncBundleIds;

    // 0=success, 1=failure
    enum ResultStatus {
        SUCCESS,
        FAILURE
    }

    event StateSyncResult(uint256 indexed counter, ResultStatus indexed status, bytes message);
    event NewBundleCommit(uint256 indexed startId, uint256 indexed endId, bytes32 root);

    /**
     * @notice commits merkle root of multiple StateSync objects
     * @param bundle Bundle of state sync objects to be committed
     * @param signature bundle signed by validators
     * @param bitmap bitmap of which validators signed the message
     */
    function commit(
        StateSyncBundle calldata bundle,
        bytes calldata signature,
        bytes calldata bitmap
    ) external onlySystemCall {
        require(bundle.startId == lastCommittedId + 1, "INVALID_START_ID");
        require(bundle.endId >= bundle.startId, "INVALID_END_ID");

        _checkPubkeyAggregation(keccak256(abi.encode(bundle)), signature, bitmap);

        bundles[bundleCounter++] = bundle;

        stateSyncBundleIds.push(bundle.endId);
        lastCommittedId = bundle.endId;

        emit NewBundleCommit(bundle.startId, bundle.endId, bundle.root);
    }

    /**
     * @notice submits leaf of tree of root data for execution
     * @dev function does not have to be called from client
     * and can be called arbitrarily so long as proper data/proofs are supplied
     * @param proof array of merkle proofs
     * @param obj state sync objects being executed
     */
    function execute(bytes32[] calldata proof, StateSync calldata obj) external {
        StateSyncBundle memory bundle = getBundleByStateSyncId(obj.id);

        require(
            keccak256(abi.encode(obj)).checkMembership(obj.id - bundle.startId, bundle.root, proof),
            "INVALID_PROOF"
        );

        _executeStateSync(obj);
    }

    /**
     * @notice submits leaf of tree of root data for execution
     * @dev function does not have to be called from client
     * and can be called arbitrarily so long as proper data/proofs are supplied
     * @param proofs array of merkle proofs
     * @param objs array of state sync objects being executed
     */
    function batchExecute(bytes32[][] calldata proofs, StateSync[] calldata objs) external {
        uint256 length = proofs.length;

        for (uint256 i = 0; i < length; ) {
            StateSyncBundle memory bundle = getBundleByStateSyncId(objs[i].id);

            bool isMember = keccak256(abi.encode(objs[i])).checkMembership(
                objs[i].id - bundle.startId,
                bundle.root,
                proofs[i]
            );

            if (!isMember) {
                unchecked {
                    ++i;
                }
                continue; // skip execution for bad proofs
            }

            _executeStateSync(objs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice get submitted root for a state sync id
     * @param id state sync to get the root for
     */
    function getRootByStateSyncId(uint256 id) external view returns (bytes32) {
        bytes32 root = bundles[stateSyncBundleIds.findUpperBound(id)].root;

        require(root != bytes32(0), "StateReceiver: NO_ROOT_FOR_STATESYNC_ID");

        return root;
    }

    /**
     * @notice get bundle for a state sync id
     * @param id state sync to get the root for
     */
    function getBundleByStateSyncId(uint256 id) public view returns (StateSyncBundle memory) {
        uint256 idx = stateSyncBundleIds.findUpperBound(id);

        require(idx != stateSyncBundleIds.length, "StateReceiver: NO_BUNDLE_FOR_STATESYNC_ID");

        return bundles[idx];
    }

    /**
     * @notice internal function to execute a state sync object
     * @param obj StateSync object to be executed
     */
    function _executeStateSync(StateSync calldata obj) private {
        // Execute `onStateReceive` method on target using max gas limit
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint256,address,bytes)",
            obj.id,
            obj.sender,
            obj.data
        );

        // slither-disable-next-line calls-loop,low-level-calls
        (bool success, bytes memory returnData) = obj.receiver.call{gas: MAX_GAS}(paramData); // solhint-disable-line avoid-low-level-calls

        // emit a ResultEvent indicating whether invocation of state sync was successful or not
        if (success) {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.SUCCESS, returnData);
        } else {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.FAILURE, returnData);
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
