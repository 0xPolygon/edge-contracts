// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * NOT_STARTED - child chain is not live, genesis validators can be added
 * COMPLETED - child chain is live
 */
enum GenesisStatus {
    NOT_STARTED,
    COMPLETED
}

struct GenesisAccount {
    address addr;
    uint256 preminedTokens;
    uint256 stakedTokens;
    bool isValidator;
}

struct GenesisSet {
    GenesisAccount[] genesisAccounts;
    GenesisStatus status;
    mapping(address => uint256) indices;
}

library GenesisLib {
    /**
     * @notice inserts an account into the genesis set
     * @param self GenesisSet struct
     * @param account address of the account
     * @param preminedTokens amount of unstaked premined tokens
     * @param stakedTokens amount of staked tokens
     * @param isVal indicates if account is a validator
     */
    function insert(GenesisSet storage self, address account, uint256 preminedTokens, uint256 stakedTokens, bool isVal) internal {
        assert(self.status == GenesisStatus.NOT_STARTED);
        uint256 index = self.indices[account];
        if (index == 0) {
            // insert into set
            // use index starting with 1, 0 is empty by default
            index = self.genesisAccounts.length + 1;
            self.indices[account] = index;
            self.genesisAccounts.push(GenesisAccount(account, preminedTokens, stakedTokens, isVal));
        } else {
            // update values
            uint256 idx = _indexOf(self, account);
            GenesisAccount storage genesisValidator = self.genesisAccounts[idx];
            genesisValidator.preminedTokens += preminedTokens;
            genesisValidator.stakedTokens += stakedTokens;
        }
    }

    /**
     * @notice finalizes the current genesis set
     */
    function finalize(GenesisSet storage self) internal {
        require(self.status == GenesisStatus.NOT_STARTED, "GenesisLib: already finalized");
        self.status = GenesisStatus.COMPLETED;
    }

    /**
     * @notice returns the current genesis set
     * @param self GenesisSet struct
     * @return genesisValidators array of genesis validators and their initial stake
     */
    function set(GenesisSet storage self) internal view returns (GenesisAccount[] memory) {
        return self.genesisAccounts;
    }

    function completed(GenesisSet storage self) internal view returns (bool) {
        return self.status == GenesisStatus.COMPLETED;
    }

    function isValidator(GenesisSet storage self, address account) internal view returns(bool) {
        uint256 index = self.indices[account];
        if (index == 0) {
            return false;
        }

        GenesisAccount storage genesisValidator = self.genesisAccounts[--index];
        return genesisValidator.isValidator;
    }

    /**
     * @notice returns index of a specific validator
     * @dev indices returned from this function start from 0
     * @param self the GenesisSet struct
     * @param account address of the account whose index is being queried
     * @return index the index of the validator in the set
     */
    function _indexOf(GenesisSet storage self, address account) private view returns (uint256 index) {
        index = self.indices[account];
        assert(index != 0); // currently index == 0 is unreachable
        return index - 1;
    }
}
