// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/test/blade/DeployChildERC20.s.sol";
import "script/deployment/test/blade/DeployChildERC20Predicate.s.sol";
import "script/deployment/test/blade/DeployChildERC20PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployChildERC721.s.sol";
import "script/deployment/test/blade/DeployChildERC721Predicate.s.sol";
import "script/deployment/test/blade/DeployChildERC721PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployChildERC1155.s.sol";
import "script/deployment/test/blade/DeployChildERC1155Predicate.s.sol";
import "script/deployment/test/blade/DeployChildERC1155PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployEIP1559Burn.s.sol";
import "script/deployment/test/blade/DeployL2StateSender.s.sol";
import "script/deployment/test/blade/validator/DeployEpochManager.s.sol";
import "script/deployment/test/blade/DeployNativeERC20.s.sol";
import "script/deployment/test/blade/DeployNativeERC20Mintable.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC20Predicate.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC20PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC721Predicate.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC721PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC1155Predicate.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC1155PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployStateReceiver.s.sol";
import "script/deployment/test/blade/DeploySystem.s.sol";
import "script/deployment/test/blade/staking/DeployStakeManager.s.sol";

contract DeployBladeContracts is
    EpochManagerDeployer,
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
    L2StateSenderDeployer,
    NativeERC20Deployer,
    NativeERC20MintableDeployer,
    RootMintableERC20PredicateDeployer,
    RootMintableERC20PredicateAccessListDeployer,
    RootMintableERC721PredicateDeployer,
    RootMintableERC721PredicateAccessListDeployer,
    RootMintableERC1155PredicateDeployer,
    RootMintableERC1155PredicateAccessListDeployer,
    StateReceiverDeployer,
    SystemDeployer,
    StakeManagerDeployer
{
    using stdJson for string;

    address public proxyAdmin;
    address public epochManagerLogic;
    address public epochManagerProxy;
    address public childERC20Logic;
    address public childERC20Proxy;
    address public childERC20PredicateLogic;
    address public childERC20PredicateProxy;
    address public childERC20PredicateAccessListLogic;
    address public childERC20PredicateAccessListProxy;
    address public childERC721Logic;
    address public childERC721Proxy;
    address public childERC721PredicateLogic;
    address public childERC721PredicateProxy;
    address public childERC721PredicateAccessListLogic;
    address public childERC721PredicateAccessListProxy;
    address public childERC1155Logic;
    address public childERC1155Proxy;
    address public childERC1155PredicateLogic;
    address public childERC1155PredicateProxy;
    address public childERC1155PredicateAccessListLogic;
    address public childERC1155PredicateAccessListProxy;
    address public eip1559BurnLogic;
    address public eip1559BurnProxy;
    address public l2StateSender;
    address public nativeERC20Logic;
    address public nativeERC20Proxy;
    address public nativeERC20MintableLogic;
    address public nativeERC20MintableProxy;
    address public rootMintableERC20PredicateLogic;
    address public rootMintableERC20PredicateProxy;
    address public rootMintableERC20PredicateAccessListLogic;
    address public rootMintableERC20PredicateAccessListProxy;
    address public rootMintableERC721PredicateLogic;
    address public rootMintableERC721PredicateProxy;
    address public rootMintableERC721PredicateAccessListLogic;
    address public rootMintableERC721PredicateAccessListProxy;
    address public rootMintableERC1155PredicateLogic;
    address public rootMintableERC1155PredicateProxy;
    address public rootMintableERC1155PredicateAccessListLogic;
    address public rootMintableERC1155PredicateAccessListProxy;
    address public stateReceiver;
    address public system;
    address public stakeManagerLogic;
    address public stakeManagerProxy;

    function run() external {
        string memory config = vm.readFile("script/deployment/bladeContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        stateReceiver = deployStateReceiver();

        (epochManagerLogic, epochManagerProxy) = deployEpochManager(
            proxyAdmin,
            config.readAddress('["EpochManager"].newStakeManager'),
            config.readAddress('["EpochManager"].newRewardToken'),
            config.readAddress('["EpochManager"].newRewardWallet'),
            config.readAddress('["EpochManager"].newNetworkParams')
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
            config.readAddress('["NativeERC20"].predicate_'),
            config.readAddress('["NativeERC20"].owner_'),
            config.readAddress('["NativeERC20"].rootToken_'),
            config.readString('["NativeERC20"].name_'),
            config.readString('["NativeERC20"].symbol_'),
            uint8(config.readUint('["NativeERC20"].decimals_')),
            config.readUint('["NativeERC20"].tokenSupply_')
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

        (stakeManagerLogic, stakeManagerProxy) = deployStakeManager(
            proxyAdmin,
            config.readAddress('["StakeManager"].newStakingToken'),
            config.readAddress('["StakeManager"].newBls'),
            config.readAddress('["StakeManager"].newEpochManager'),
            config.readAddress('["EpochManager"].newNetworkParams'),
            config.readAddress('["StakeManager"].newOwner'),
            config.readString('["StakeManager"].newDomain'),
            abi.decode(config.readBytes('["StakeManager"].newGenesisValidators'), (GenesisValidator[]))
        );

        system = deploySystem();
    }
}
