// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {NetworkParams} from "contracts/child/NetworkParams.sol";

import {ValidatorSet as Old_ValidatorSet, ValidatorInit as Old_ValidatorInit} from "./deployed/ValidatorSet.sol";
import {ValidatorSet, ValidatorInit} from "contracts/child/validator/ValidatorSet.sol";
import {ValidatorSetHardforkProxy} from "contracts/child/validator/proxy/hardfork/ValidatorSetHardforkProxy.sol";

import {RewardPool as Old_RewardPool} from "./deployed/RewardPool.sol";
import {RewardPool} from "contracts/child/validator/RewardPool.sol";
import {RewardPoolHardforkProxy} from "contracts/child/validator/proxy/hardfork/RewardPoolHardforkProxy.sol";

import {NetworkParams as Old_NetworkParams} from "./deployed/NetworkParams.sol";
import {NetworkParams} from "contracts/child/NetworkParams.sol";
import {NetworkParamsHardforkProxy} from "contracts/child/proxy/hardfork/NetworkParamsHardforkProxy.sol";

import {ForkParams as Old_ForkParams} from "./deployed/ForkParams.sol";
import {ForkParams} from "contracts/child/ForkParams.sol";
import {ForkParamsHardforkProxy} from "contracts/child/proxy/hardfork/ForkParamsHardforkProxy.sol";

/// @notice Checks if all modified OpenZeppelin contracts are up-to-date.
contract Hardfork_ModifiedOpenZeppelinContractsCheck is Test {
    function test_CheckModifiedOpenZeppelinContracts() public {
        string[] memory cmd = new string[](2);
        cmd[0] = "node";
        cmd[1] = "scripts/maintenance/checkModifiedOpenZeppelinContracts.js";

        bytes memory out = vm.ffi(cmd);

        require(out.length > 0, "Script contains errors.");

        bytes32 ok = keccak256("All modified OpenZeppelin contracts up-to-date.");

        require(keccak256(out) == ok, string(out));
    }
}

abstract contract Initialized is Test {
    // Actors.
    address internal immutable ADMIN = makeAddr("ADMIN");
    address internal immutable VALIDATOR_A = makeAddr("VALIDATOR_A");
    address internal immutable VALIDATOR_B = makeAddr("VALIDATOR_B");

    // Other required contracts.
    address internal stateSender;
    address internal stateReceiver;
    address internal rootChainManager;
    //
    address internal rewardToken;
    address internal rewardWallet;

    // Old versions.
    Old_ValidatorSet internal old_validatorSet;
    bytes32 constant EXPECTED_STORAGE_START_VS = bytes32(uint256(201));
    //
    Old_RewardPool internal old_rewardPool;
    bytes32 constant EXPECTED_STORAGE_START_RP = bytes32(uint256(50));
    //
    Old_NetworkParams internal old_networkParams;
    //
    Old_ForkParams internal old_forkParams;

    /// @notice Deploys or mocks other required contracts.
    /// @dev Called by `setUp`.
    function _setUp_OtherContracts() internal virtual {
        stateSender = makeAddr("stateSender");
        stateReceiver = makeAddr("stateReceiver");
        rootChainManager = makeAddr("rootChainManager");
        //
        rewardToken = makeAddr("newRewardToken");
        rewardWallet = makeAddr("newRewardWallet");
    }

    function setUp() public virtual {
        _setUp_OtherContracts();

        old_validatorSet = new Old_ValidatorSet();
        //
        old_rewardPool = new Old_RewardPool();
        //
        old_networkParams = new Old_NetworkParams(address(1), 1, 1, 1, 1);
        //
        old_forkParams = new Old_ForkParams(ADMIN);

        // Simulate initializations without proxies!

        Old_ValidatorInit[] memory initialValidators = new Old_ValidatorInit[](2);
        initialValidators[0] = Old_ValidatorInit({addr: VALIDATOR_A, stake: 300});
        initialValidators[1] = Old_ValidatorInit({addr: VALIDATOR_B, stake: 100});

        old_validatorSet.initialize(stateSender, stateReceiver, rootChainManager, 1, initialValidators);
        //
        old_rewardPool.initialize(rewardToken, rewardWallet, address(old_validatorSet), 1);
    }
}

contract HardforkTest_Initialized is Initialized {
    /// @dev Do not use the already deployed contract for this test.
    function test_Old_ValidatorSet_OGStorageStart() public {
        old_validatorSet = new Old_ValidatorSet();
        Old_ValidatorInit[] memory initialValidators = new Old_ValidatorInit[](2);
        initialValidators[0] = Old_ValidatorInit({addr: VALIDATOR_A, stake: 300});
        initialValidators[1] = Old_ValidatorInit({addr: VALIDATOR_B, stake: 100});
        old_validatorSet.initialize(stateSender, stateReceiver, rootChainManager, 1, initialValidators);

        assertEq(vm.load(address(old_validatorSet), EXPECTED_STORAGE_START_VS), bytes32(uint256(uint160(stateSender))));
    }

    /// @dev Do not use the already deployed contract for this test.
    function test_Old_RewardPool_OGStorageStart() public {
        old_rewardPool = new Old_RewardPool();
        old_rewardPool.initialize(rewardToken, rewardWallet, address(old_validatorSet), 1);

        assertEq(
            vm.load(address(old_rewardPool), EXPECTED_STORAGE_START_RP),
            bytes32(bytes.concat(hex"00000000000000000000", abi.encodePacked(rewardToken), hex"0001"))
        );
    }

    function test_Old_NetworkParams_StorageSlots() public {
        for (uint i; i < 4; i++) {
            assertNotEq(vm.load(address(old_networkParams), bytes32(i)), bytes32(uint256(0)));
        }
    }

    function test_Old_ForkParams_StorageSlots() public {
        assertEq(old_forkParams.owner(), ADMIN);
    }
}

abstract contract StateContaining is Initialized {
    function setUp() public virtual override {
        super.setUp();
    }
}

contract HardforkTest_StateContaining is StateContaining {}

abstract contract Hardforked is StateContaining {
    // New versions.
    ValidatorSet internal validatorSet;
    RewardPool internal rewardPool;
    NetworkParams internal networkParams;
    ForkParams internal forkParams;

    // Helpers.
    address internal validatorSetProxyAddr;
    ValidatorSet internal validatorSetViaProxy;
    //
    address internal rewardPoolProxyAddr;
    RewardPool internal rewardPoolViaProxy;
    //
    address internal networkParamsProxyAddr;
    NetworkParams internal networkParamsViaProxy;
    //
    address internal forkParamsProxyAddr;
    ForkParams internal forkParamsViaProxy;

    function setUp() public virtual override {
        super.setUp();

        // Hardfork!

        // 1. Deploy new logic.
        validatorSet = new ValidatorSet();
        //
        rewardPool = new RewardPool();
        //
        networkParams = new NetworkParams();
        //
        forkParams = new ForkParams();

        // 2. Replace contracts with proxies.
        deployCodeTo("ValidatorSetHardforkProxy.sol", address(old_validatorSet));
        //
        deployCodeTo("RewardPoolHardforkProxy.sol", address(old_rewardPool));
        //
        deployCodeTo("NetworkParamsHardforkProxy.sol", address(old_networkParams));
        //
        deployCodeTo("ForkParamsHardforkProxy.sol", address(old_forkParams));

        validatorSetProxyAddr = address(old_validatorSet);
        //
        rewardPoolProxyAddr = address(old_rewardPool);
        //
        networkParamsProxyAddr = address(old_networkParams);
        //
        forkParamsProxyAddr = address(old_forkParams);

        // 3. Set up proxies.
        ValidatorSetHardforkProxy(payable(validatorSetProxyAddr)).setUpProxy(
            address(validatorSet),
            ADMIN,
            address(networkParams)
        );
        //
        RewardPoolHardforkProxy(payable(rewardPoolProxyAddr)).setUpProxy(
            address(rewardPool),
            ADMIN,
            address(networkParams)
        );
        //
        NetworkParamsHardforkProxy(payable(networkParamsProxyAddr)).setUpProxy(
            address(networkParams),
            ADMIN,
            NetworkParams.InitParams({
                newOwner: ADMIN,
                newCheckpointBlockInterval: 2,
                newEpochSize: 2,
                newEpochReward: 2,
                newSprintSize: 2,
                newMinValidatorSetSize: 2,
                newMaxValidatorSetSize: 2,
                newWithdrawalWaitPeriod: 2,
                newBlockTime: 2,
                newBlockTimeDrift: 2,
                newVotingDelay: 2,
                newVotingPeriod: 2,
                newProposalThreshold: 2,
                newBaseFeeChangeDenom: 2
            })
        );
        //
        ForkParamsHardforkProxy(payable(forkParamsProxyAddr)).setUpProxy(address(forkParams), ADMIN);

        validatorSetViaProxy = ValidatorSet(validatorSetProxyAddr);
        //
        rewardPoolViaProxy = RewardPool(rewardPoolProxyAddr);
        //
        networkParamsViaProxy = NetworkParams(networkParamsProxyAddr);
        //
        forkParams = ForkParams(forkParamsProxyAddr);
    }
}

contract HardforkTest_Hardforked is Hardforked {
    function test_ValidatorSetHardforkProxy_RevertOn_setUpProxy() public {
        vm.expectRevert("ProxyBase: Already set up.");

        ValidatorSetHardforkProxy(payable(validatorSetProxyAddr)).setUpProxy(address(0), address(0), address(0));
    }

    function test_ValidatorSet_RevertOn_initialize() public {
        vm.expectRevert("Initializable: contract is already initialized");

        validatorSetViaProxy.initialize(
            stateSender,
            stateReceiver,
            rootChainManager,
            address(networkParams),
            new ValidatorInit[](0)
        );
    }

    function test_ValidatorSet_networkParams() public {
        assertEq(
            vm.load(validatorSetProxyAddr, bytes32(uint256(209))),
            bytes32(uint256(uint160(address(networkParams))))
        );
    }

    /// @dev Do not use the already deployed contract for this test.
    function test_ValidatorSet_OGStorageStart() public {
        validatorSet = new ValidatorSet();
        ValidatorInit[] memory initialValidators = new ValidatorInit[](2);
        initialValidators[0] = ValidatorInit({addr: VALIDATOR_A, stake: 300});
        initialValidators[1] = ValidatorInit({addr: VALIDATOR_B, stake: 100});
        validatorSet.initialize(
            stateSender,
            stateReceiver,
            rootChainManager,
            address(networkParams),
            initialValidators
        );

        assertEq(vm.load(address(validatorSet), EXPECTED_STORAGE_START_VS), bytes32(uint256(uint160(stateSender))));
    }

    function test_RewardPoolHardforkProxy_RevertOn_setUpProxy() public {
        vm.expectRevert("ProxyBase: Already set up.");

        RewardPoolHardforkProxy(payable(rewardPoolProxyAddr)).setUpProxy(address(0), address(0), address(0));
    }

    function test_RewardPool_RevertOn_initialize() public {
        vm.expectRevert("Initializable: contract is already initialized");

        rewardPoolViaProxy.initialize(
            address(rewardToken),
            rewardWallet,
            address(validatorSetViaProxy),
            address(networkParams)
        );
    }

    function test_RewardPool_networkParams() public {
        assertEq(vm.load(rewardPoolProxyAddr, bytes32(uint256(56))), bytes32(uint256(uint160(address(networkParams)))));
    }

    /// @dev Do not use the already deployed contract for this test.
    function test_RewardPool_OGStorageStart() public {
        rewardPool = new RewardPool();
        rewardPool.initialize(address(rewardToken), rewardWallet, address(validatorSet), address(networkParams));

        assertEq(
            vm.load(rewardPoolProxyAddr, EXPECTED_STORAGE_START_RP),
            bytes32(bytes.concat(hex"00000000000000000000", abi.encodePacked(rewardToken), hex"0001"))
        );
    }

    function test_NetworkParamsHardforkProxy_RevertOn_setUpProxy() public {
        NetworkParams.InitParams memory initParams;

        vm.expectRevert("ProxyBase: Already set up.");

        NetworkParamsHardforkProxy(payable(networkParamsProxyAddr)).setUpProxy(address(0), address(0), initParams);
    }

    function test_NetworkParams_RevertOn_initialize() public {
        NetworkParams.InitParams memory initParams;

        vm.expectRevert("Initializable: contract is already initialized");

        networkParamsViaProxy.initialize(initParams);
    }

    function test_NetworkParams_StorageSlots() public {
        assertEq(networkParamsViaProxy.owner(), ADMIN);
        assertEq(networkParamsViaProxy.checkpointBlockInterval(), 2);
        assertEq(networkParamsViaProxy.epochSize(), 2);
        assertEq(networkParamsViaProxy.epochReward(), 2);
        assertEq(networkParamsViaProxy.sprintSize(), 2);
        assertEq(networkParamsViaProxy.minValidatorSetSize(), 2);
        assertEq(networkParamsViaProxy.maxValidatorSetSize(), 2);
        assertEq(networkParamsViaProxy.withdrawalWaitPeriod(), 2);
        assertEq(networkParamsViaProxy.blockTime(), 2);
        assertEq(networkParamsViaProxy.blockTimeDrift(), 2);
        assertEq(networkParamsViaProxy.votingDelay(), 2);
        assertEq(networkParamsViaProxy.votingPeriod(), 2);
        assertEq(networkParamsViaProxy.proposalThreshold(), 2);
    }

    function test_ForkParamsHardforkProxy_RevertOn_setUpProxy() public {
        vm.expectRevert("ProxyBase: Already set up.");

        ForkParamsHardforkProxy(payable(address(old_forkParams))).setUpProxy(address(0), address(0));
    }

    function test_ForkParams_RevertOn_initialize() public {
        vm.expectRevert("Initializable: contract is already initialized");

        forkParams.initialize(address(0));
    }

    function test_ForkParams_StorageSlots() public {
        assertEq(forkParams.owner(), ADMIN);
    }
}
