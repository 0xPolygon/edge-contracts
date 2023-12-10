// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {StakeManager} from "contracts/blade/staking/StakeManager.sol";
import {EpochManager} from "contracts/blade/validator/EpochManager.sol";
import {GenesisValidator} from "contracts/interfaces/blade/staking/IStakeManager.sol";
import {Epoch} from "contracts/interfaces/blade/validator/IEpochManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {NetworkParams} from "contracts/blade/NetworkParams.sol";
import {BLS} from "contracts/common/BLS.sol";
import "contracts/interfaces/Errors.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Uninitialized is Test {
    address public constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    MockERC20 token;
    StakeManager stakeManager;
    BLS bls;

    EpochManager epochManager;
    NetworkParams networkParams;
    string testDomain = "STAKE_MANAGER";

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address jim = makeAddr("jim");
    address rewardWallet = makeAddr("rewardWallet");

    uint256 newStakeAmount = 100;
    uint256 newUnstakeAmount = 150;
    uint256 bobInitialStake = 400;
    uint256 aliceInitialStake = 200;
    uint256 jimInitialStake = 100;
    uint256[2][] public aggMessagePoints;

    function setUp() public virtual {
        token = new MockERC20();
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);
        token.mint(jim, 1000 ether);

        bls = new BLS();
        stakeManager = new StakeManager();
        epochManager = new EpochManager();
        networkParams = new NetworkParams();

        vm.prank(alice);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(bob);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(jim);
        token.approve(address(stakeManager), type(uint256).max);

        epochManager.initialize(address(stakeManager), address(token), rewardWallet, address(networkParams));
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        GenesisValidator[] memory validators = new GenesisValidator[](3);
        validators[0] = GenesisValidator({
            addr: bob,
            stake: bobInitialStake,
            blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]
        });
        validators[1] = GenesisValidator({
            addr: alice,
            stake: aliceInitialStake,
            blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]
        });
        validators[2] = GenesisValidator({
            addr: jim,
            stake: jimInitialStake,
            blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]
        });

        stakeManager.initialize(
            address(token),
            address(bls),
            address(epochManager),
            address(networkParams),
            bob,
            testDomain,
            validators
        );
    }
}

abstract contract Unstaked is Initialized {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(alice);
        stakeManager.unstake(newUnstakeAmount);

        vm.prank(SYSTEM);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        epochManager.commitEpoch(1, 64, epoch);

        vm.prank(address(stakeManager));
        token.approve(alice, type(uint256).max);
    }
}

contract StakeManager_Initialize is Uninitialized {
    function testInititialize() public {
        GenesisValidator[] memory validators = new GenesisValidator[](3);
        validators[0] = GenesisValidator({
            addr: bob,
            stake: bobInitialStake,
            blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]
        });
        validators[1] = GenesisValidator({
            addr: alice,
            stake: aliceInitialStake,
            blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]
        });
        validators[2] = GenesisValidator({
            addr: jim,
            stake: jimInitialStake,
            blsKey: [type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max]
        });

        stakeManager.initialize(
            address(token),
            address(bls),
            address(epochManager),
            address(networkParams),
            bob,
            testDomain,
            validators
        );
    }
}

contract StakeManager_Stake is Initialized, StakeManager {
    function test_Stake(uint256 amount) public {
        vm.assume(amount <= newStakeAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeAdded(bob, amount);

        vm.prank(bob);
        stakeManager.stake(amount);
        uint256 totalStake = stakeManager.balanceOf(bob) + aliceInitialStake + jimInitialStake;
        assertEq(stakeManager.totalStake(), totalStake, "total stake mismatch");
        assertEq(stakeManager.stakeOf(bob), amount + bobInitialStake, "stake of mismatch");
        assertEq(token.balanceOf(address(stakeManager)), totalStake, "token balance mismatch");
    }
}

contract StakeManager_WithdrawStake is Unstaked, StakeManager {
    function test_WithdrawStake() public {
        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(alice, newUnstakeAmount);

        assertEq(stakeManager.withdrawable(alice), newUnstakeAmount, "withdrawable stake mismatch");
        assertEq(stakeManager.stakeOf(alice), aliceInitialStake - newUnstakeAmount, "expected stake missmatch");

        vm.prank(alice);
        stakeManager.withdraw();
    }
}

abstract contract Whitelisted is Initialized {
    address kevin = makeAddr("kevin");
    address mike = makeAddr("mike");

    function setUp() public virtual override {
        super.setUp();
        token.mint(kevin, 1000 ether);
        address[] memory validators = new address[](2);
        validators[0] = address(this);
        validators[1] = kevin;
        vm.prank(bob);
        stakeManager.whitelistValidators(validators);
    }

    function getSignatureAndPubKey(address addr) public returns (uint256[2] memory, uint256[4] memory) {
        string[] memory cmd = new string[](5);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/bridge/generateMsgStakeManager.ts";
        cmd[3] = toHexString(addr);
        cmd[4] = toHexString(address(stakeManager));
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

contract StakeManager_Registered is Whitelisted {
    event ValidatorRegistered(address indexed validator, uint256[4] blsKey);
    event RemovedFromWhitelist(address indexed validator);

    function test_RevertValidatorNotWhitelisted() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "WHITELIST"));
        vm.prank(mike);
        uint256[2] memory signature;
        uint256[4] memory pubkey;
        stakeManager.register(signature, pubkey, newStakeAmount);
    }

    function test_RevertEmptySignature() public {
        uint256[2] memory signature = [uint256(0), uint256(0)];
        uint256[4] memory pubkey = [uint256(0), uint256(0), uint256(0), uint256(0)];
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector, kevin));
        vm.prank(kevin);
        stakeManager.register(signature, pubkey, newStakeAmount);
    }

    function test_RevertInvalidSignature() public {
        (uint256[2] memory signature, uint256[4] memory pubkey) = getSignatureAndPubKey(kevin);
        signature[0] = signature[0] + 1;
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector, kevin));
        vm.prank(kevin);
        stakeManager.register(signature, pubkey, newStakeAmount);
    }

    function test_SuccessfulRegistration() public {
        (uint256[2] memory signature, uint256[4] memory pubKey) = getSignatureAndPubKey(kevin);
        vm.startPrank(kevin);
        token.approve(address(stakeManager), type(uint256).max);
        stakeManager.register(signature, pubKey, newStakeAmount);
        uint256 stake = stakeManager.stakeOf(kevin);

        assertEq(stake, newStakeAmount, "expected same stake");
    }
}
