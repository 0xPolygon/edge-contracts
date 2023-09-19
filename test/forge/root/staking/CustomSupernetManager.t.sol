// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import "contracts/common/BLS.sol";
import "contracts/root/StateSender.sol";
import {ExitHelper} from "contracts/root/ExitHelper.sol";
import {StakeManager} from "contracts/root/staking/StakeManager.sol";
import {CustomSupernetManager, Validator, GenesisValidator} from "contracts/root/staking/CustomSupernetManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import "contracts/interfaces/Errors.sol";

abstract contract Uninitialized is Test {
    BLS bls;
    StateSender stateSender;
    address childValidatorSet;
    address exitHelper;
    string constant DOMAIN = "CUSTOM_SUPERNET_MANAGER";
    bytes32 internal constant callerSlotOnExitHelper = bytes32(uint256(3));
    MockERC20 token;
    StakeManager stakeManager;
    CustomSupernetManager supernetManager;

    function setUp() public virtual {
        bls = new BLS();
        stateSender = new StateSender();
        childValidatorSet = makeAddr("childValidatorSet");
        exitHelper = address(new ExitHelper());
        token = new MockERC20();
        stakeManager = new StakeManager();
        supernetManager = new CustomSupernetManager();
        stakeManager.initialize(address(token));
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        supernetManager.initialize(
            address(stakeManager),
            address(bls),
            address(stateSender),
            address(token),
            childValidatorSet,
            exitHelper,
            DOMAIN
        );
    }
}

abstract contract Registered is Initialized {
    address alice = makeAddr("alice");

    function setUp() public virtual override {
        super.setUp();
        stakeManager.registerChildChain(address(supernetManager));
    }
}

abstract contract Whitelisted is Registered {
    address bob = makeAddr("bob");

    function setUp() public virtual override {
        super.setUp();
        address[] memory validators = new address[](2);
        validators[0] = address(this);
        validators[1] = alice;
        supernetManager.whitelistValidators(validators);
    }

    function getSignatureAndPubKey(address addr) public returns (uint256[2] memory, uint256[4] memory) {
        string[] memory cmd = new string[](5);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/root/generateMsgSupernetManager.ts";
        cmd[3] = toHexString(addr);
        cmd[4] = toHexString(address(supernetManager));
        bytes memory out = vm.ffi(cmd);

        (uint256[2] memory signature, uint256[4] memory pubkey) = abi.decode(out, (uint256[2], uint256[4]));

        return (signature, pubkey);
    }

    function toHexString(address addr) public pure returns (string memory) {
        bytes memory buffer = abi.encodePacked(addr);

        // Fixed buffer size for hexadecimal conversion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}

abstract contract ValidatorsRegistered is Whitelisted {
    uint256 amount = 1000;

    function setUp() public virtual override {
        super.setUp();
        register(address(this));
        register(alice);
        token.mint(address(this), amount * 2);
        token.mint(alice, amount);
        token.mint(bob, amount);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(alice);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(bob);
        token.approve(address(stakeManager), type(uint256).max);
    }

    function register(address addr) public {
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(addr);
        vm.prank(addr);
        supernetManager.register(signature, pubkey);
    }
}

abstract contract GenesisStaked is ValidatorsRegistered {
    function setUp() public virtual override {
        super.setUp();
        stakeManager.stakeFor(1, amount);
    }
}

abstract contract FinalizedGenesis is GenesisStaked {
    function setUp() public virtual override {
        super.setUp();
        supernetManager.finalizeGenesis();
    }
}

abstract contract EnabledStaking is FinalizedGenesis {
    function setUp() public virtual override {
        super.setUp();
        supernetManager.enableStaking();
    }
}

abstract contract Slashed is EnabledStaking {
    bytes32 private constant SLASH_SIG = keccak256("SLASH");
    uint256 internal slashingPercentage = 50; // sent from ValidatorSet
    uint256 internal slashIncentivePercentage = 30; // sent from ValidatorSet

    function setUp() public virtual override {
        super.setUp();
        address[] memory validatorsToSlash = new address[](1);
        validatorsToSlash[0] = address(this);
        bytes memory callData = abi.encode(SLASH_SIG, validatorsToSlash, slashingPercentage, slashIncentivePercentage);
        vm.store(exitHelper, callerSlotOnExitHelper, bytes32(uint256(uint160(makeAddr("MEV"))))); // simulate caller of exit()
        vm.prank(exitHelper);
        supernetManager.onL2StateReceive(1, childValidatorSet, callData);
        vm.store(exitHelper, callerSlotOnExitHelper, bytes32(0));
    }
}

contract CustomSupernetManager_Initialize is Uninitialized {
    function testInititialize() public {
        supernetManager.initialize(
            address(stakeManager),
            address(bls),
            address(stateSender),
            address(token),
            childValidatorSet,
            exitHelper,
            DOMAIN
        );
        assertEq(supernetManager.owner(), address(this), "should set owner");
        assertEq((supernetManager.domain()), keccak256(abi.encodePacked(DOMAIN)), "should set and hash DOMAIN");
    }
}

contract CustomSupernetManager_RegisterWithStakeManager is Initialized {
    function test_Register() public {
        assertEq(supernetManager.id(), 0);
        stakeManager.registerChildChain(address(supernetManager));
        assertEq(supernetManager.id(), 1, "should set id");
    }
}

contract CustomSupernetManager_UpdateWhitelist is Registered {
    event AddedToWhitelist(address indexed validator);

    function test_RevertNotOwner() public {
        address[] memory validators = new address[](2);
        validators[0] = address(this);
        validators[1] = alice;
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        supernetManager.whitelistValidators(validators);
    }

    function testUpdateWhitelist() public {
        address[] memory validators = new address[](2);
        validators[0] = address(this);
        validators[1] = alice;
        vm.expectEmit(true, true, true, true);
        emit AddedToWhitelist(address(this));
        vm.expectEmit(true, true, true, true);
        emit AddedToWhitelist(alice);
        supernetManager.whitelistValidators(validators);
        assertTrue(supernetManager.getValidator(address(this)).isWhitelisted, "should whitelist validator");
        assertTrue(supernetManager.getValidator(alice).isWhitelisted, "should whitelist validator");
    }
}

contract CustomSupernetManager_RegisterValidator is Whitelisted {
    event ValidatorRegistered(address indexed validator, uint256[4] blsKey);
    event RemovedFromWhitelist(address indexed validator);

    function test_RevertValidatorNotWhitelisted() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "WHITELIST"));
        vm.prank(bob);
        uint256[2] memory signature;
        uint256[4] memory pubkey;
        supernetManager.register(signature, pubkey);
    }

    function test_RevertEmptySignature() public {
        uint256[2] memory signature = [uint256(0), uint256(0)];
        uint256[4] memory pubkey = [uint256(0), uint256(0), uint256(0), uint256(0)];
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector, address(this)));
        supernetManager.register(signature, pubkey);
    }

    function test_RevertInvalidSignature() public {
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(address(this));
        signature[0] = signature[0] + 1;
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector, address(this)));
        supernetManager.register(signature, pubkey);
    }

    function test_SuccessfulRegistration() public {
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(address(this));
        vm.expectEmit(true, true, true, true);
        emit RemovedFromWhitelist(address(this));
        vm.expectEmit(true, true, true, true);
        emit ValidatorRegistered(address(this), pubkey);
        supernetManager.register(signature, pubkey);
        Validator memory validator = supernetManager.getValidator(address(this));
        assertEq(
            keccak256(abi.encodePacked(validator.blsKey)),
            keccak256(abi.encodePacked(pubkey)),
            "should set blsKey"
        );
        assertTrue(validator.isActive, "should set isRegistered");
        assertFalse(validator.isWhitelisted, "should remove from whitelist");
    }
}

contract CustomSupernetManager_StakeGenesis is ValidatorsRegistered {
    function test_RevertNotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "VALIDATOR"));
        vm.prank(bob);
        stakeManager.stakeFor(1, amount);
    }

    function test_SuccessfulStakeGenesis() public {
        stakeManager.stakeFor(1, amount);
        GenesisValidator[] memory genesisValidators = supernetManager.genesisSet();
        assertEq(genesisValidators.length, 1, "should set genesisSet");
        GenesisValidator memory validator = genesisValidators[0];
        assertEq(validator.validator, address(this), "should set validator address");
        assertEq(validator.initialStake, amount, "should set amount");
    }

    function test_MultipleStakes() public {
        stakeManager.stakeFor(1, amount / 2);
        stakeManager.stakeFor(1, amount / 2);
        GenesisValidator[] memory genesisValidators = supernetManager.genesisSet();
        assertEq(genesisValidators.length, 1, "should set genesisSet");
        GenesisValidator memory validator = genesisValidators[0];
        assertEq(validator.validator, address(this), "should set validator address");
        assertEq(validator.initialStake, amount, "should set amount");
    }
}

contract CustomSupernetManager_FinalizeGenesis is GenesisStaked {
    event GenesisFinalized(uint256 amountValidators);

    function test_RevertNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        supernetManager.finalizeGenesis();
    }

    function test_RevertEnableStaking() public {
        vm.expectRevert("GenesisLib: not finalized");
        supernetManager.enableStaking();
    }

    function test_SuccessFinaliseGenesis() public {
        vm.expectEmit(true, true, true, true);
        emit GenesisFinalized(1);
        supernetManager.finalizeGenesis();
    }
}

contract CustomSupernetManager_EnableStaking is FinalizedGenesis {
    event StakingEnabled();

    function test_RevertNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        supernetManager.enableStaking();
    }

    function test_RevertFinalizeGenesis() public {
        vm.expectRevert("GenesisLib: already finalized");
        supernetManager.finalizeGenesis();
    }

    function test_RevertStaking() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "Wait for genesis"));
        stakeManager.stakeFor(1, amount);
    }

    function test_SuccessEnableStaking() public {
        vm.expectEmit(true, true, true, true);
        emit StakingEnabled();
        supernetManager.enableStaking();
    }
}

contract CustomSupernetManager_PostGenesis is EnabledStaking {
    function test_RevertEnableStaking() public {
        vm.expectRevert("GenesisLib: already enabled");
        supernetManager.enableStaking();
    }
}

contract CustomSupernetManager_StakingPostGenesis is EnabledStaking {
    event StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    bytes32 private constant STAKE_SIG = keccak256("STAKE");

    function test_SuccessfulStakePostGenesis() public {
        vm.expectEmit(true, true, true, true);
        emit StateSynced(1, address(supernetManager), childValidatorSet, abi.encode(STAKE_SIG, address(this), amount));
        stakeManager.stakeFor(1, amount);
    }
}

contract CustomSupernetManager_Unstake is EnabledStaking {
    bytes32 private constant UNSTAKE_SIG = keccak256("UNSTAKE");
    event ValidatorDeactivated(address indexed validator);

    function test_RevertNotCalledByExitHelper() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "_exitHelper"));
        supernetManager.onL2StateReceive(1, childValidatorSet, "");
    }

    function test_RevertChildValidatorSetNotSender() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "_exitHelper"));
        vm.prank(exitHelper);
        supernetManager.onL2StateReceive(1, alice, "");
    }

    function test_SuccessfulFullWithdrawal() public {
        bytes memory callData = abi.encode(UNSTAKE_SIG, address(this), amount);
        vm.expectEmit(true, true, true, true);
        emit ValidatorDeactivated(address(this));
        vm.prank(exitHelper);
        supernetManager.onL2StateReceive(1, childValidatorSet, callData);
        assertEq(stakeManager.stakeOf(address(this), 1), 0, "should withdraw all");
        assertEq(supernetManager.getValidator(address(this)).isActive, false, "should deactivate");
    }

    function test_SuccessfulPartWithdrawal(uint256 unstakeAmount) public {
        vm.assume(unstakeAmount != 0 && unstakeAmount < amount);
        bytes memory callData = abi.encode(UNSTAKE_SIG, address(this), unstakeAmount);
        vm.prank(exitHelper);
        supernetManager.onL2StateReceive(1, childValidatorSet, callData);
        assertEq(stakeManager.stakeOf(address(this), 1), amount - unstakeAmount, "should not withdraw all");
        assertEq(supernetManager.getValidator(address(this)).isActive, true, "should not deactivate");
    }
}
