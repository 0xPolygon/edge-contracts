// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract MockERC721 is ERC721PresetMinterPauserAutoId("TEST", "TEST", "lorem") {}
