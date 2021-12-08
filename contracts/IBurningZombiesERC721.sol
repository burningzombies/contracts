// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBurningZombiesERC721 is IERC721Enumerable {
    function minterOf(uint256 tokenId) external view returns (address);
}
