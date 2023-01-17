// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/modules/ICVSAccessControl.sol";
import "./CVSStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

abstract contract CVSAccessControl is ICVSAccessControl, CVSStorage, Ownable2StepUpgradeable {
    /**
     * @inheritdoc ICVSAccessControl
     */
    function addToWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _addToWhitelist(whitelistAddreses[i]);
        }
    }

    /**
     * @inheritdoc ICVSAccessControl
     */
    function removeFromWhitelist(address[] calldata whitelistAddreses) external onlyOwner {
        for (uint256 i = 0; i < whitelistAddreses.length; i++) {
            _removeFromWhitelist(whitelistAddreses[i]);
        }
    }

    function _addToWhitelist(address account) internal {
        whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    function _removeFromWhitelist(address account) internal {
        whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }
}
