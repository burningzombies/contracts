// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INeonMonstersMinters.sol";

contract PriceCalculator is Ownable {
    INeonMonstersMinters private _neonMonstersMinters;

    IERC20[] private _erc20Tokens;
    IERC721[] private _erc721Tokens;
    IERC721 private _neonMonsters;

    mapping(address => uint256) private _minHoldingAmounts;

    function addERC20Token(IERC20 address_, uint256 min) external onlyOwner {
        _erc20Tokens.push(address_);
        _minHoldingAmounts[address(address_)] = min;
    }

    function addERC721Token(IERC721 address_, uint256 min) external onlyOwner {
        _erc721Tokens.push(address_);
        _minHoldingAmounts[address(address_)] = min;
    }

    function setNeonMonstersMinters(INeonMonstersMinters address_)
        external
        onlyOwner
    {
        _neonMonstersMinters = address_;
    }

    function setNeonMonsters(IERC721 address_) external onlyOwner {
        _neonMonsters = address_;
        _erc721Tokens.push(address_);
        _minHoldingAmounts[address(address_)] = 5;
    }

    function getPrice(
        uint256 segmentNo,
        address sender,
        uint256 price,
        uint256 balance
    ) public view returns (uint256) {
        if (segmentNo != 0 && balance >= 3) return price;

        if (segmentNo == 0) {
            if (
                balance < (uint256(_neonMonsters.balanceOf(sender)) / 10) &&
                _neonMonstersMinters.isMinter(sender)
            ) return price / 10;
        }

        // NFT Round
        if (segmentNo > 0 && segmentNo < 5) {
            for (uint256 i = 0; _erc721Tokens.length > i; i++) {
                if (
                    _erc721Tokens[i].balanceOf(sender) >=
                    _minHoldingAmounts[address(_erc721Tokens[i])]
                ) return price - ((price / 100) * 10);
            }
        }

        // DeFi Round
        for (uint256 i = 0; _erc20Tokens.length > i; i++) {
            if (
                _erc20Tokens[i].balanceOf(sender) >=
                _minHoldingAmounts[address(_erc20Tokens[i])]
            ) return price - ((price / 100) * 10);
        }

        return price;
    }
}
