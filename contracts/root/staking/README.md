# Staking

##### Contracts for the SupernetManager

This subdirectory contains contracts making up the Supernet Manager, which serves as a hub for validators to stake on all Supernets tied to a root chain.

## CustomSupernetManager

An implementation of the abstract `SupernetManager` contract.

## StakeManager

Manages validator stake across all Supernets.

## StakeManagerChildData

Abstract contract used by StakeManager. Holds a registry of all Supernets.

## StakeManagerStakingData

Abstract contract used by StakeManager. Managers validator stake.

## SupernetManager

Abstract contract meant to be customized as a Supernet Manager.
