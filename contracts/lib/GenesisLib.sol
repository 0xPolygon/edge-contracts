// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * NOT_STARTED - child chain is not live, genesis validators can be added
 * IN_PROGRESS - no longer accepting genesis validators, child chain is created
 * COMPLETED - child chain is live, validators can stake normally
 */
enum GenesisStatus {
    NOT_STARTED,
    IN_PROGRESS,
    COMPLETED
}

struct GenesisValidator {
    address validator;
    uint256 initialStake;
}

struct GenesisSet {
    GenesisValidator[] genesisValidators;
    GenesisStatus status;
    mapping(address => uint256) indices;
}

library GenesisLib {
    /**
     * @notice inserts a validator into the genesis set
     * @param self GenesisSet struct
     * @param validator address of the validator
     * @param stake amount to add to the validators genesis stake
     */
    function insert(GenesisSet storage self, address validator, uint256 stake) internal {
        assert(self.status == GenesisStatus.NOT_STARTED);
        uint256 index = self.indices[validator];
        if (index == 0) {
            // insert into set
            // use index starting with 1, 0 is empty by default
            index = self.genesisValidators.length + 1;
            self.indices[validator] = index;
            self.genesisValidators.push(GenesisValidator(validator, stake));
        } else {
            // update values
            GenesisValidator storage genesisValidator = self.genesisValidators[_indexOf(self, validator)];
            genesisValidator.initialStake += stake;
        }
    }

    /**
     * @notice finalizes the current genesis set
     */
    function finalize(GenesisSet storage self) internal {
        require(self.status == GenesisStatus.NOT_STARTED, "GenesisLib: already finalized");
        self.status = GenesisStatus.IN_PROGRESS;
    }

    /**
     * @notice enables staking after the genesis set has been finalized
     */
    function enableStaking(GenesisSet storage self) internal {
        GenesisStatus status = self.status;
        if (status == GenesisStatus.NOT_STARTED) revert("GenesisLib: not finalized");
        if (status == GenesisStatus.COMPLETED) revert("GenesisLib: already enabled");
        self.status = GenesisStatus.COMPLETED;
    }

    /**
     * @notice returns the current genesis set
     * @param self GenesisSet struct
     * @return genesisValidators array of genesis validators and their initial stake
     */
    function set(GenesisSet storage self) internal view returns (GenesisValidator[] memory) {
        return self.genesisValidators;
    }

    function gatheringGenesisValidators(GenesisSet storage self) internal view returns (bool) {
        return self.status == GenesisStatus.NOT_STARTED;
    }

    function completed(GenesisSet storage self) internal view returns (bool) {
        return self.status == GenesisStatus.COMPLETED;
    }

    /**
     * @notice returns index of a specific validator
     * @dev indices returned from this function start from 0
     * @param self the GenesisSet struct
     * @param validator address of the validator whose index is being queried
     * @return index the index of the validator in the set
     */
    function _indexOf(GenesisSet storage self, address validator) private view returns (uint256 index) {
        index = self.indices[validator];
        assert(index != 0); // currently index == 0 is unreachable
        return index - 1;
    }
}
