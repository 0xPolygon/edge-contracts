# Validator

##### Contracts directly related to validating

This subdirectory contains contracts directly related to validating on Supernets.

## RewardPool

This contract manages the distribution of assets as rewards for validators validating blocks on the child chain. The contract accounts for rewards due to validators, which validators can withdraw from the contract when distributed.

## ValidatorSet

Manages most direct validator tasks, such as committing epochs or announcing intent to unstake.

## `proxy/hardfork/` and `legacy-compat/`

`RewardPool` and `ValidatorSet` are both intended to be genesis contracts, as in they are intended to be instantiated at the genesis of the chain, as opposed to traditionally deployed. In Edge's earlier stages, the decision has been made to proxify all genesis contracts, as to say that a proxy will be deployed for each at genesis, pointing towards its implementation. This should allow updates to genesis contracts without needing a hardfork or regenesis. The `proxy/hardfork/` directory contains proxies for `RewardPool` and `ValidatorSet`, in case you have to hardfork. A specific proxy was needed for each due to a situation that arose from production Supernets which had not proxified, but then needed to update to a newer version. These custom proxies were created so that they would be able to continue using the historical state of `RewardPool` and `ValidatorSet`. A more generic proxy for the rest of the genesis contracts (which do not create state) can be found in [`contracts/lib/BasicGenesisProxy.sol`](../../lib/BasicGenesisProxy.sol).

`legacy-compat/` serves a similar purpose. In the migrated contracts there were some variables and functions that changed. This directory contains contracts from OpenZeppelin which we have tailored in order to synchronize the storage slots of the older and newer versions of `RewardPool` and `ValidatorSet`.
