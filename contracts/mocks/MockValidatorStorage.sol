// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/ValidatorStorage.sol";

contract MockValidatorStorage {
    // slither-disable-next-line uninitialized-state
    uint256[4] blsKey;

    using ValidatorStorageLib for ValidatorTree;
    ValidatorTree validators;

    uint256 public constant ACTIVE_VALIDATORS = 5;

    function balanceOf(address account) public view returns (uint256 balance) {
        balance = validators.totalStakeOf(account);
    }

    function insert(address account, uint256 amount) external {
        Validator memory data = Validator({
            blsKey: blsKey,
            stake: amount,
            commission: 0,
            withdrawableRewards: 0,
            active: true
        });
        validators.insert(account, data);
    }

    function remove(address account) external {
        validators.remove(account);
    }

    function min() external view returns (address account, uint256 balance) {
        account = validators.first();
        balance = balanceOf(account);
    }

    function max() external view returns (address account, uint256 balance) {
        account = validators.last();
        balance = balanceOf(account);
    }

    function activeValidators() external view returns (address[] memory) {
        uint256 validatorCount = validators.count >= ACTIVE_VALIDATORS ? ACTIVE_VALIDATORS : validators.count;

        address[] memory validatorAddresses = new address[](validatorCount);

        if (validatorCount == 0) return validatorAddresses;

        address tmpValidator = validators.last();
        validatorAddresses[0] = tmpValidator;

        for (uint256 i = 1; i < validatorCount; i++) {
            tmpValidator = validators.prev(tmpValidator);
            validatorAddresses[i] = tmpValidator;
        }

        return validatorAddresses;
    }

    function allValidators() external view returns (address[] memory) {
        address[] memory validatorAddresses = new address[](validators.count);

        address tmpValidator = validators.last();
        validatorAddresses[0] = tmpValidator;

        for (uint256 i = 1; i < validators.count; i++) {
            tmpValidator = validators.prev(tmpValidator);
            validatorAddresses[i] = tmpValidator;
        }

        return validatorAddresses;
    }
}
