// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/common/IValidatorSets.sol";
import "../interfaces/common/IBLS.sol";
import "../interfaces/common/IBN256G2.sol";

contract ValidatorSets is IValidatorSets, Initializable {
    uint256 public currentValidatorSetLength;
    uint256 public totalVotingPower;
    bytes32 public constant DOMAIN_VALIDATOR = keccak256("DOMAIN_VALIDATOR_CHANGE");
    IBLS public bls;
    IBN256G2 public bn256G2;

    mapping(uint256 => Validator)[] public validatorSets;
    bytes32 public currentValidatorSetHash;

    /**
     * @notice Initialization function for CheckpointManager
     * @dev Contract can only be initialized once
     * @param newBls Address of the BLS library contract
     * @param newBn256G2 Address of the BLS library contract
     */
    function initialize(IBLS newBls, IBN256G2 newBn256G2, Validator[] calldata newValidatorSet) public initializer {
        bls = newBls;
        bn256G2 = newBn256G2;
        currentValidatorSetLength = newValidatorSet.length;
        _setNewValidatorSet(newValidatorSet);
    }

    /**
     * Update the validator set
     // TODO add to interface
     */
    function updateValidatorCheck(
        uint256[2] calldata signature,
        Validator[] calldata newValidatorSet,
        bytes calldata bitmap
    ) external {
        bytes memory hash = abi.encode(
            keccak256(abi.encode(currentValidatorSetHash, keccak256(abi.encode(newValidatorSet))))
        );
        _verifySignature(bls.hashToPoint(DOMAIN_VALIDATOR, hash), signature, bitmap);

        _setNewValidatorSet(newValidatorSet);
    }

    function _setNewValidatorSet(Validator[] calldata newValidatorSet) internal {
        uint256 length = newValidatorSet.length;
        currentValidatorSetLength = length;
        currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;

        uint256 curValSet = validatorSets.length;
        validatorSets.push();

        for (uint256 i = 0; i < length; ++i) {
            uint256 votingPower = newValidatorSet[i].votingPower;
            require(votingPower > 0, "VOTING_POWER_ZERO");
            totalPower += votingPower;
            validatorSets[curValSet][i] = newValidatorSet[i];
        }
        totalVotingPower = totalPower;
    }

    /**
     * @notice Internal function that asserts that the signature is valid and that the required threshold is met
     * @param message The message that was signed by validators (i.e. checkpoint hash)
     * @param signature The aggregated signature submitted by the proposer
     */
    function _verifySignature(
        uint256[2] memory message,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) internal view {
        uint256 curValSet = validatorSets.length - 1;

        uint256 length = currentValidatorSetLength;
        // slither-disable-next-line uninitialized-local
        uint256[4] memory aggPubkey;
        uint256 aggVotingPower = 0;
        for (uint256 i = 0; i < length; ) {
            if (_getValueFromBitmap(bitmap, i)) {
                if (aggVotingPower == 0) {
                    aggPubkey = validatorSets[curValSet][i].blsKey;
                } else {
                    uint256[4] memory blsKey = validatorSets[curValSet][i].blsKey;
                    // slither-disable-next-line calls-loop
                    (aggPubkey[0], aggPubkey[1], aggPubkey[2], aggPubkey[3]) = bn256G2.ecTwistAdd(
                        aggPubkey[0],
                        aggPubkey[1],
                        aggPubkey[2],
                        aggPubkey[3],
                        blsKey[0],
                        blsKey[1],
                        blsKey[2],
                        blsKey[3]
                    );
                }
                aggVotingPower += validatorSets[curValSet][i].votingPower;
            }
            unchecked {
                ++i;
            }
        }

        require(aggVotingPower != 0, "BITMAP_IS_EMPTY");
        require(aggVotingPower > ((2 * totalVotingPower) / 3), "INSUFFICIENT_VOTING_POWER");

        (bool callSuccess, bool result) = bls.verifySingle(signature, aggPubkey, message);

        require(callSuccess && result, "SIGNATURE_VERIFICATION_FAILED");
    }

    function _getValueFromBitmap(bytes calldata bitmap, uint256 index) private pure returns (bool) {
        uint256 byteNumber = index / 8;
        uint8 bitNumber = uint8(index % 8);

        if (byteNumber >= bitmap.length) {
            return false;
        }

        // Get the value of the bit at the given 'index' in a byte.
        return uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
