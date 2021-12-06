// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NeonMonsters is ERC721 {
    constructor() ERC721("Neon Monsters Mock", "NEMOMOCK") {
        _safeMint(_msgSender(), 0);
        _safeMint(_msgSender(), 1);
        _safeMint(_msgSender(), 2);
        _safeMint(_msgSender(), 3);
        _safeMint(_msgSender(), 4);
        _safeMint(_msgSender(), 5);
        _safeMint(_msgSender(), 6);
        _safeMint(_msgSender(), 7);
        _safeMint(_msgSender(), 8);
        _safeMint(_msgSender(), 9);
        _safeMint(_msgSender(), 10);
        _safeMint(_msgSender(), 11);
    }
}
