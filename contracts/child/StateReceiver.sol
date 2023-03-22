// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import {System} from "./System.sol";
import {Merkle} from "../common/Merkle.sol";

/**
 * @title State Receiver
 * @author Polygon Technology (JD Kanani @jdkanani, @QEDK)
 * @notice executes and relays the state data on the child chain
 */
// solhint-disable reason-string
contract StateReceiver is System {
    using ArraysUpgradeable for uint256[];
    using Merkle for bytes32;

    struct StateSync {
        uint256 id;
        address sender;
        address receiver;
        bytes data;
    }

    struct StateSyncCommitment {
        uint256 startId;
        uint256 endId;
        bytes32 root;
    }

    /// @custom:security write-protection="onlySystemCall()"
    uint256 public commitmentCounter;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public lastCommittedId;

    mapping(uint256 => bool) public processedStateSyncs;
    mapping(uint256 => StateSyncCommitment) public commitments;
    uint256[] public commitmentIds;

    event StateSyncResult(uint256 indexed counter, bool indexed status, bytes message);
    event NewCommitment(uint256 indexed startId, uint256 indexed endId, bytes32 root);

    /**
     * @notice commits merkle root of multiple StateSync objects
     * @param commitment commitment of state sync objects
     * @param signature commitment signed by validators
     * @param bitmap bitmap of which validators signed the message
     */
    function commit(
        StateSyncCommitment calldata commitment,
        bytes calldata signature,
        bytes calldata bitmap
    ) external onlySystemCall {
        require(commitment.startId == lastCommittedId + 1, "INVALID_START_ID");
        require(commitment.endId >= commitment.startId, "INVALID_END_ID");

        _checkPubkeyAggregation(keccak256(abi.encode(commitment)), signature, bitmap);

        commitments[commitmentCounter++] = commitment;

        commitmentIds.push(commitment.endId);
        lastCommittedId = commitment.endId;

        emit NewCommitment(commitment.startId, commitment.endId, commitment.root);
    }

    /**
     * @notice submits leaf of tree of root data for execution
     * @dev function does not have to be called from client
     * and can be called arbitrarily so long as proper data/proofs are supplied
     * @param proof array of merkle proofs
     * @param obj state sync objects being executed
     */
    function execute(bytes32[] calldata proof, StateSync calldata obj) external {
        StateSyncCommitment memory commitment = getCommitmentByStateSyncId(obj.id);

        require(
            keccak256(abi.encode(obj)).checkMembershipWithHeight(
                obj.id - commitment.startId,
                commitment.endId - commitment.startId + 1,
                commitment.root,
                proof
            ),
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

        require(proofs.length == objs.length, "StateReceiver: UNMATCHED_LENGTH_PARAMETERS");
        for (uint256 i = 0; i < length; ) {
            StateSyncCommitment memory commitment = getCommitmentByStateSyncId(objs[i].id);

            bool isMember = keccak256(abi.encode(objs[i])).checkMembershipWithHeight(
                objs[i].id - commitment.startId,
                commitment.endId - commitment.startId + 1,
                commitment.root,
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
        bytes32 root = commitments[commitmentIds.findUpperBound(id)].root;

        require(root != bytes32(0), "StateReceiver: NO_ROOT_FOR_ID");

        return root;
    }

    /**
     * @notice get commitment for a state sync id
     * @param id state sync to get the root for
     */
    function getCommitmentByStateSyncId(uint256 id) public view returns (StateSyncCommitment memory) {
        uint256 idx = commitmentIds.findUpperBound(id);

        require(idx != commitmentIds.length, "StateReceiver: NO_COMMITMENT_FOR_ID");

        return commitments[idx];
    }

    /**
     * @notice internal function to execute a state sync object
     * @param obj StateSync object to be executed
     */
    function _executeStateSync(StateSync calldata obj) private {
        require(!processedStateSyncs[obj.id], "StateReceiver: STATE_SYNC_IS_PROCESSED");
        // Skip transaction if client has added flag, or receiver has no code
        if (obj.receiver.code.length == 0) {
            emit StateSyncResult(obj.id, false, "");
            return;
        }

        processedStateSyncs[obj.id] = true;

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = obj.receiver.call(
            abi.encodeWithSignature("onStateReceive(uint256,address,bytes)", obj.id, obj.sender, obj.data)
        );

        // if state sync fails, revert flag
        if (!success) processedStateSyncs[obj.id] = false;

        // emit a ResultEvent indicating whether invocation of state sync was successful or not
        // slither-disable-next-line reentrancy-events
        emit StateSyncResult(obj.id, success, returnData);
    }

    /**
     * @notice verifies an aggregated BLS signature using BLS precompile
     * @param message plaintext of signed message
     * @param signature the signed message
     * @param bitmap bitmap of which validators have signed
     */
    function _checkPubkeyAggregation(bytes32 message, bytes calldata signature, bytes calldata bitmap) internal view {
        // verify signatures` for provided sig data and sigs bytes
        // solhint-disable-next-line avoid-low-level-calls
        // slither-disable-next-line low-level-calls,calls-loop
        (bool callSuccess, bytes memory returnData) = VALIDATOR_PKCHECK_PRECOMPILE.staticcall{
            gas: VALIDATOR_PKCHECK_PRECOMPILE_GAS
        }(abi.encode(message, signature, bitmap));
        bool verified = abi.decode(returnData, (bool));
        require(callSuccess && verified, "SIGNATURE_VERIFICATION_FAILED");
    }
}
