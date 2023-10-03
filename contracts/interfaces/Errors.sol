// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

error Unauthorized(string only);
error StakeRequirement(string src, string msg);
error InvalidSignature(address signer);

error InvalidInitiator();
error InvalidValidatorSetHash();
error NoEventRootForBlockNumber();
error NoEventRootForEpoch();
error VotingPowerZero();
error BitmapIsEmpty();
error InsufficientVotingPower();
error SignatureVerificationFailed();
error InvalidEpoch();
error EmptyCheckpoint();
error NotContract();
error OnlyExitHelper();
error OnlyRootPredicate();
error BadInitialization();
error UnmappedToken();
error BurnFailed();
error InvalidLength();
error MintFailed();
error OnlyChildPredicate();
error InvalidToken();
error AlreadyMapped();
error InvalidReceiver();
error ExceedsMaxLength();
error InvalidInput();
error IdAlreadySet();
error InvalidId();
error InvalidAddress();
error InvalidManager();
error OnlyStakeManager();
error NotInitialized();
error ExitAlreadyProcessed();
error InvalidProof();
