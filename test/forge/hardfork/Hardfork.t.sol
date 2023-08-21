// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";

import {NetworkParams} from "contracts/child/NetworkParams.sol";

import {ValidatorSet as Old_ValidatorSet, ValidatorInit as Old_ValidatorInit} from "./deployed/ValidatorSet.sol";
import {ValidatorSet, ValidatorInit} from "contracts/child/validator/ValidatorSet.sol";
import {ValidatorSetProxy} from "contracts/child/validator/proxy/ValidatorSetProxy.sol";

import {RewardPool as Old_RewardPool} from "./deployed/RewardPool.sol";
import {RewardPool} from "contracts/child/validator/RewardPool.sol";
import {RewardPoolProxy} from "contracts/child/validator/proxy/RewardPoolProxy.sol";

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
}

abstract contract StateContaining is Initialized {
    function setUp() public virtual override {
        super.setUp();
    }
}

contract HardforkTest_StateContaining is StateContaining {}

abstract contract Hardforked is StateContaining {
    // Other required contracts.
    NetworkParams internal networkParams;

    // New versions.
    ValidatorSet internal validatorSet;
    RewardPool internal rewardPool;

    // Helpers.
    address internal validatorSetProxyAddr;
    ValidatorSet internal validatorSetViaProxy;
    //
    address internal rewardPoolProxyAddr;
    RewardPool internal rewardPoolViaProxy;

    function _setUp_OtherContracts() internal virtual override {
        super._setUp_OtherContracts();

        networkParams = new NetworkParams();
        networkParams.initialize(
            NetworkParams.InitParams({
                newOwner: address(1),
                newCheckpointBlockInterval: 1,
                newEpochSize: 1,
                newEpochReward: 1,
                newSprintSize: 1,
                newMinValidatorSetSize: 1,
                newMaxValidatorSetSize: 1,
                newWithdrawalWaitPeriod: 1,
                newBlockTime: 1,
                newBlockTimeDrift: 1,
                newVotingDelay: 1,
                newVotingPeriod: 1,
                newProposalThreshold: 1
            })
        );
    }

    function setUp() public virtual override {
        super.setUp();

        // Hardfork!

        // 1. Deploy new logic.
        validatorSet = new ValidatorSet();
        //
        rewardPool = new RewardPool();

        // 2. Replace contracts with proxies.
        deployCodeTo(
            "ValidatorSetProxy.sol",
            //abi.encode(address(validatorSet), ADMIN, address(networkParams)),
            address(old_validatorSet)
        );
        //
        deployCodeTo(
            "RewardPoolProxy.sol",
            abi.encode(address(rewardPool), ADMIN, address(networkParams)),
            address(old_rewardPool)
        );

        validatorSetProxyAddr = address(old_validatorSet);
        //
        rewardPoolProxyAddr = address(old_rewardPool);

        // 3. Set up proxies.
        ValidatorSetProxy(payable(validatorSetProxyAddr)).setUpProxy(
            address(validatorSet),
            ADMIN,
            "",
            address(networkParams)
        );
        //
        RewardPoolProxy(payable(rewardPoolProxyAddr)).setUpProxy(
            address(rewardPool),
            ADMIN,
            "",
            address(networkParams)
        );

        validatorSetViaProxy = ValidatorSet(validatorSetProxyAddr);
        //
        rewardPoolViaProxy = RewardPool(rewardPoolProxyAddr);
    }
}

contract HardforkTest_Hardforked is Hardforked {
    function test_ValidatorSetProxy_RevertOn_setUpProxy() public {
        vm.expectRevert("GenesisProxy: Already set up.");

        ValidatorSetProxy(payable(validatorSetProxyAddr)).setUpProxy(address(0), address(0), "", address(0));
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

    function test_RewardPoolProxy_RevertOn_setUpProxy() public {
        vm.expectRevert("GenesisProxy: Already set up.");

        RewardPoolProxy(payable(rewardPoolProxyAddr)).setUpProxy(address(0), address(0), "", address(0));
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
}
