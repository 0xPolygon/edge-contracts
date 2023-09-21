// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/test/child/validator/DeployRewardPool.s.sol";
import "script/deployment/test/child/validator/DeployValidatorSet.s.sol";
import "script/deployment/test/child/DeployChildERC20.s.sol";
import "script/deployment/test/child/DeployChildERC20Predicate.s.sol";
import "script/deployment/test/child/DeployChildERC20PredicateAccessList.s.sol";
import "script/deployment/test/child/DeployChildERC721.s.sol";
import "script/deployment/test/child/DeployChildERC721Predicate.s.sol";
import "script/deployment/test/child/DeployChildERC721PredicateAccessList.s.sol";
import "script/deployment/test/child/DeployChildERC1155.s.sol";
import "script/deployment/test/child/DeployChildERC1155Predicate.s.sol";
import "script/deployment/test/child/DeployChildERC1155PredicateAccessList.s.sol";
import "script/deployment/test/child/DeployEIP1559Burn.s.sol";
import "script/deployment/test/child/DeployForkParams.s.sol";
import "script/deployment/test/child/DeployL2StateSender.s.sol";
import "script/deployment/test/child/DeployNativeERC20.s.sol";
import "script/deployment/test/child/DeployNativeERC20Mintable.s.sol";
import "script/deployment/test/child/DeployNetworkParams.s.sol";
import "script/deployment/test/child/DeployRootMintableERC20Predicate.s.sol";
import "script/deployment/test/child/DeployRootMintableERC20PredicateAccessList.s.sol";
import "script/deployment/test/child/DeployRootMintableERC721Predicate.s.sol";
import "script/deployment/test/child/DeployRootMintableERC721PredicateAccessList.s.sol";
import "script/deployment/test/child/DeployRootMintableERC1155Predicate.s.sol";
import "script/deployment/test/child/DeployRootMintableERC1155PredicateAccessList.s.sol";
import "script/deployment/test/child/DeployStateReceiver.s.sol";
import "script/deployment/test/child/DeploySystem.s.sol";

contract DeployChildContracts is
    RewardPoolDeployer,
    ValidatorSetDeployer,
    ChildERC20Deployer,
    ChildERC20PredicateDeployer,
    ChildERC20PredicateAccessListDeployer,
    ChildERC721Deployer,
    ChildERC721PredicateDeployer,
    ChildERC721PredicateAccessListDeployer,
    ChildERC1155Deployer,
    ChildERC1155PredicateDeployer,
    ChildERC1155PredicateAccessListDeployer,
    EIP1559BurnDeployer,
    ForkParamsDeployer,
    L2StateSenderDeployer,
    NativeERC20Deployer,
    NativeERC20MintableDeployer,
    NetworkParamsDeployer,
    RootMintableERC20PredicateDeployer,
    RootMintableERC20PredicateAccessListDeployer,
    RootMintableERC721PredicateDeployer,
    RootMintableERC721PredicateAccessListDeployer,
    RootMintableERC1155PredicateDeployer,
    RootMintableERC1155PredicateAccessListDeployer,
    StateReceiverDeployer,
    SystemDeployer
{
    using stdJson for string;

    address proxyAdmin;
    address rewardPoolLogic;
    address rewardPoolProxy;
    address validatorSetLogic;
    address validatorSetProxy;
    address childERC20Logic;
    address childERC20Proxy;
    address childERC20PredicateLogic;
    address childERC20PredicateProxy;
    address childERC20PredicateAccessListLogic;
    address childERC20PredicateAccessListProxy;
    address childERC721Logic;
    address childERC721Proxy;
    address childERC721PredicateLogic;
    address childERC721PredicateProxy;
    address childERC721PredicateAccessListLogic;
    address childERC721PredicateAccessListProxy;
    address childERC1155Logic;
    address childERC1155Proxy;
    address childERC1155PredicateLogic;
    address childERC1155PredicateProxy;
    address childERC1155PredicateAccessListLogic;
    address childERC1155PredicateAccessListProxy;
    address eip1559BurnLogic;
    address eip1559BurnProxy;
    address forkParamsLogic;
    address forkParamsProxy;
    address l2StateSender;
    address nativeERC20Logic;
    address nativeERC20Proxy;
    address nativeERC20MintableLogic;
    address nativeERC20MintableProxy;
    address networkParamsLogic;
    address networkParamsProxy;
    address rootMintableERC20PredicateLogic;
    address rootMintableERC20PredicateProxy;
    address rootMintableERC20PredicateAccessListLogic;
    address rootMintableERC20PredicateAccessListProxy;
    address rootMintableERC721PredicateLogic;
    address rootMintableERC721PredicateProxy;
    address rootMintableERC721PredicateAccessListLogic;
    address rootMintableERC721PredicateAccessListProxy;
    address rootMintableERC1155PredicateLogic;
    address rootMintableERC1155PredicateProxy;
    address rootMintableERC1155PredicateAccessListLogic;
    address rootMintableERC1155PredicateAccessListProxy;
    address stateReceiver;
    address system;

    function run() external {
        string memory config = vm.readFile("script/deployment/childContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        stateReceiver = deployStateReceiver();

        (networkParamsLogic, networkParamsProxy) = deployNetworkParams(
            proxyAdmin,
            abi.decode(config.readBytes('["NetworkParams"].initParams'), (NetworkParams.InitParams))
        );

        (validatorSetLogic, validatorSetProxy) = deployValidatorSet(
            proxyAdmin,
            config.readAddress('["ValidatorSet"].newStateSender'),
            stateReceiver,
            config.readAddress('["ValidatorSet"].newRootChainManager'),
            networkParamsProxy,
            abi.decode(config.readBytes('["ValidatorSet"].initialValidators'), (ValidatorInit[]))
        );

        (rewardPoolLogic, rewardPoolProxy) = deployRewardPool(
            proxyAdmin,
            config.readAddress('["RewardPool"].newRewardToken'),
            config.readAddress('["RewardPool"].newRewardWallet'),
            validatorSetProxy,
            networkParamsProxy
        );

        (childERC20Logic, childERC20Proxy) = deployChildERC20(
            proxyAdmin,
            config.readAddress('["ChildERC20"].rootToken_'),
            config.readString('["ChildERC20"].name_'),
            config.readString('["ChildERC20"].symbol_'),
            uint8(config.readUint('["ChildERC20"].decimals_'))
        );

        l2StateSender = deployL2StateSender();

        (childERC20PredicateLogic, childERC20PredicateProxy) = deployChildERC20Predicate(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            config.readAddress('["ChildERC20Predicate"].newRootERC20Predicate'),
            config.readAddress('["ChildERC20Predicate"].newChildTokenTemplate'),
            config.readAddress('["ChildERC20Predicate"].newNativeTokenRootAddress')
        );

        (childERC20PredicateAccessListLogic, childERC20PredicateAccessListProxy) = deployChildERC20PredicateAccessList(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            config.readAddress('["ChildERC20PredicateAccessList"].newRootERC20Predicate'),
            config.readAddress('["ChildERC20PredicateAccessList"].newChildTokenTemplate'),
            config.readAddress('["ChildERC20PredicateAccessList"].newNativeTokenRootAddress'),
            config.readBool('["ChildERC20PredicateAccessList"].newUseAllowList'),
            config.readBool('["ChildERC20PredicateAccessList"].newUseBlockList'),
            config.readAddress('["ChildERC20PredicateAccessList"].newOwner')
        );

        (childERC721Logic, childERC721Proxy) = deployChildERC721(
            proxyAdmin,
            config.readAddress('["ChildERC721"].rootToken_'),
            config.readString('["ChildERC721"].name_'),
            config.readString('["ChildERC721"].symbol_')
        );

        (childERC721PredicateLogic, childERC721PredicateProxy) = deployChildERC721Predicate(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            config.readAddress('["ChildERC721Predicate"].newRootERC721Predicate'),
            config.readAddress('["ChildERC721Predicate"].newChildTokenTemplate')
        );

        (
            childERC721PredicateAccessListLogic,
            childERC721PredicateAccessListProxy
        ) = deployChildERC721PredicateAccessList(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            config.readAddress('["ChildERC721PredicateAccessList"].newRootERC721Predicate'),
            config.readAddress('["ChildERC721PredicateAccessList"].newChildTokenTemplate'),
            config.readBool('["ChildERC721PredicateAccessList"].newUseAllowList'),
            config.readBool('["ChildERC721PredicateAccessList"].newUseBlockList'),
            config.readAddress('["ChildERC721PredicateAccessList"].newOwner')
        );

        (childERC1155Logic, childERC1155Proxy) = deployChildERC1155(
            proxyAdmin,
            config.readAddress('["ChildERC1155"].rootToken_'),
            config.readString('["ChildERC1155"].uri_')
        );

        (childERC1155PredicateLogic, childERC1155PredicateProxy) = deployChildERC1155Predicate(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            config.readAddress('["ChildERC1155Predicate"].newRootERC1155Predicate'),
            config.readAddress('["ChildERC1155Predicate"].newChildTokenTemplate')
        );

        (
            childERC1155PredicateAccessListLogic,
            childERC1155PredicateAccessListProxy
        ) = deployChildERC1155PredicateAccessList(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            config.readAddress('["ChildERC1155PredicateAccessList"].newRootERC1155Predicate'),
            config.readAddress('["ChildERC1155PredicateAccessList"].newChildTokenTemplate'),
            config.readBool('["ChildERC1155PredicateAccessList"].newUseAllowList'),
            config.readBool('["ChildERC1155PredicateAccessList"].newUseBlockList'),
            config.readAddress('["ChildERC1155PredicateAccessList"].newOwner')
        );

        (eip1559BurnLogic, eip1559BurnProxy) = deployEIP1559Burn(
            proxyAdmin,
            IChildERC20Predicate(childERC20PredicateProxy),
            config.readAddress('["EIP1559Burn"].newBurnDestination')
        );

        (forkParamsLogic, forkParamsProxy) = deployForkParams(
            proxyAdmin,
            config.readAddress('["ForkParams"].newOwner')
        );

        (nativeERC20Logic, nativeERC20Proxy) = deployNativeERC20(
            proxyAdmin,
            config.readAddress('["NativeERC20"].predicate_'),
            config.readAddress('["NativeERC20"].rootToken_'),
            config.readString('["NativeERC20"].name_'),
            config.readString('["NativeERC20"].symbol_'),
            uint8(config.readUint('["NativeERC20"].decimals_')),
            config.readUint('["NativeERC20"].tokenSupply_')
        );

        (nativeERC20MintableLogic, nativeERC20MintableProxy) = deployNativeERC20Mintable(
            proxyAdmin,
            config.readAddress('["NativeERC20Mintable"].predicate_'),
            config.readAddress('["NativeERC20Mintable"].owner_'),
            config.readAddress('["NativeERC20Mintable"].rootToken_'),
            config.readString('["NativeERC20Mintable"].name_'),
            config.readString('["NativeERC20Mintable"].symbol_'),
            uint8(config.readUint('["NativeERC20Mintable"].decimals_')),
            config.readUint('["NativeERC20Mintable"].tokenSupply_')
        );

        (rootMintableERC20PredicateLogic, rootMintableERC20PredicateProxy) = deployRootMintableERC20Predicate(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            childERC20PredicateProxy,
            config.readAddress('["RootMintableERC20Predicate"].newChildTokenTemplate')
        );

        (
            rootMintableERC20PredicateAccessListLogic,
            rootMintableERC20PredicateAccessListProxy
        ) = deployRootMintableERC20PredicateAccessList(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            childERC20PredicateProxy,
            config.readAddress('["RootMintableERC20PredicateAccessList"].newChildTokenTemplate'),
            config.readBool('["RootMintableERC20PredicateAccessList"].newUseAllowList'),
            config.readBool('["RootMintableERC20PredicateAccessList"].newUseBlockList'),
            config.readAddress('["RootMintableERC20PredicateAccessList"].newOwner')
        );

        (rootMintableERC721PredicateLogic, rootMintableERC721PredicateProxy) = deployRootMintableERC721Predicate(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            childERC721PredicateProxy,
            config.readAddress('["RootMintableERC721Predicate"].newChildTokenTemplate')
        );

        (
            rootMintableERC721PredicateAccessListLogic,
            rootMintableERC721PredicateAccessListProxy
        ) = deployRootMintableERC721PredicateAccessList(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            childERC721PredicateProxy,
            config.readAddress('["RootMintableERC721PredicateAccessList"].newChildTokenTemplate'),
            config.readBool('["RootMintableERC721PredicateAccessList"].newUseAllowList'),
            config.readBool('["RootMintableERC721PredicateAccessList"].newUseBlockList'),
            config.readAddress('["RootMintableERC721PredicateAccessList"].newOwner')
        );

        (rootMintableERC1155PredicateLogic, rootMintableERC1155PredicateProxy) = deployRootMintableERC1155Predicate(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            childERC1155PredicateProxy,
            config.readAddress('["RootMintableERC1155Predicate"].newChildTokenTemplate')
        );

        (
            rootMintableERC1155PredicateAccessListLogic,
            rootMintableERC1155PredicateAccessListProxy
        ) = deployRootMintableERC1155PredicateAccessList(
            proxyAdmin,
            l2StateSender,
            stateReceiver,
            childERC1155PredicateProxy,
            config.readAddress('["RootMintableERC1155PredicateAccessList"].newChildTokenTemplate'),
            config.readBool('["RootMintableERC1155PredicateAccessList"].newUseAllowList'),
            config.readBool('["RootMintableERC1155PredicateAccessList"].newUseBlockList'),
            config.readAddress('["RootMintableERC1155PredicateAccessList"].newOwner')
        );

        system = deploySystem();
    }
}
