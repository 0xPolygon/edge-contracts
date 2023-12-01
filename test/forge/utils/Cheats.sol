// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// 💬 ABOUT
// StdCheats and custom cheats.

// 🧩 MODULES
import {StdCheats} from "forge-std/StdCheats.sol";

// 📦 BOILERPLATE
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// ⭐️ CHEATS
abstract contract Cheats is StdCheats {
    address immutable PROXY_ADMIN = makeAddr("PROXY_ADMIN");

    function proxify(string memory what, bytes memory args) internal returns (address proxyAddr) {
        address logicAddr = deployCode(what, args);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(logicAddr, PROXY_ADMIN, "");
        proxyAddr = address(proxy);
    }
}
