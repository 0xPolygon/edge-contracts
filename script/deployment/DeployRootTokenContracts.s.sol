// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import "script/deployment/root/DeployRootERC20Predicate.s.sol";
import "script/deployment/root/DeployChildMintableERC20Predicate.s.sol";
import "script/deployment/root/DeployRootERC721Predicate.s.sol";
import "script/deployment/root/DeployChildMintableERC721Predicate.s.sol";
import "script/deployment/root/DeployRootERC1155Predicate.s.sol";
import "script/deployment/root/DeployChildMintableERC1155Predicate.s.sol";

contract DeployRootTokenContracts is
    RootERC20PredicateDeployer,
    ChildMintableERC20PredicateDeployer,
    RootERC721PredicateDeployer,
    ChildMintableERC721PredicateDeployer,
    RootERC1155PredicateDeployer,
    ChildMintableERC1155PredicateDeployer
{
    using stdJson for string;

    function run()
        external
        returns (
            address rootERC20PredicateLogic,
            address rootERC20PredicateProxy,
            address childMintableERC20PredicateLogic,
            address childMintableERC20PredicateProxy,
            address rootERC721PredicateLogic,
            address rootERC721PredicateProxy,
            address childMintableERC721PredicateLogic,
            address childMintableERC721PredicateProxy,
            address rootERC1155PredicateLogic,
            address rootERC1155PredicateProxy,
            address childMintableERC1155PredicateLogic,
            address childMintableERC1155PredicateProxy
        )
    {
        string memory config = vm.readFile("script/deployment/rootTokenContractsConfig.json");

        (rootERC20PredicateLogic, rootERC20PredicateProxy) = deployRootERC20Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].stateSender'),
            config.readAddress('["common"].exitHelper'),
            config.readAddress('["RootERC20Predicate"].newChildERC20Predicate'),
            config.readAddress('["RootERC20Predicate"].newChildTokenTemplate'),
            config.readAddress('["RootERC20Predicate"].nativeTokenRootAddress')
        );

        (childMintableERC20PredicateLogic, childMintableERC20PredicateProxy) = deployChildMintableERC20Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].stateSender'),
            config.readAddress('["common"].exitHelper'),
            rootERC20PredicateProxy,
            config.readAddress('["newChildTokenTemplate"].newChildTokenTemplate')
        );

        (rootERC721PredicateLogic, rootERC721PredicateProxy) = deployRootERC721Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].stateSender'),
            config.readAddress('["common"].exitHelper'),
            config.readAddress('["RootERC721Predicate"].newChildERC721Predicate'),
            config.readAddress('["RootERC721Predicate"].newChildTokenTemplate')
        );

        (childMintableERC721PredicateLogic, childMintableERC721PredicateProxy) = deployChildMintableERC721Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].stateSender'),
            config.readAddress('["common"].exitHelper'),
            rootERC721PredicateProxy,
            config.readAddress('["ChildMintableERC721Predicate"].newChildTokenTemplate')
        );

        (rootERC1155PredicateLogic, rootERC1155PredicateProxy) = deployRootERC1155Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].stateSender'),
            config.readAddress('["common"].exitHelper'),
            config.readAddress('["RootERC1155Predicate"].newChildERC1155Predicate'),
            config.readAddress('["RootERC1155Predicate"].newChildTokenTemplate')
        );

        (childMintableERC1155PredicateLogic, childMintableERC1155PredicateProxy) = deployChildMintableERC1155Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].stateSender'),
            config.readAddress('["common"].exitHelper'),
            rootERC1155PredicateProxy,
            config.readAddress('["ChildMintableERC1155Predicate"].newChildTokenTemplate')
        );
    }
}
