// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    constructor(uint256 numberOfTokens) ERC721("ERC721 Mock", "ERC721MOCK") {
        for (uint256 i = 0; numberOfTokens > i; i++) {
            _safeMint(_msgSender(), i);
        }
    }
}
