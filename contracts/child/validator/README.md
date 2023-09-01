# Validator

##### Contracts directly related to validating

This subdirectory contains contracts directly related to validating on Supernets.

## RewardPool

This contract manages the distribution of assets as rewards for validators validating blocks on the child chain. The contract accounts for rewards due to validators, which validators can withdraw from the contract when distributed.

## ValidatorSet

Manages most direct validator tasks, such as committing epochs or announcing intent to unstake.
