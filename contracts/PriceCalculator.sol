// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INeonMonstersMinters.sol";

contract PriceCalculator is Ownable {
    INeonMonstersMinters private _neonMonstersMinters;
    IERC721 private _neonMonsters;
    IERC20 private _avaware;

    function setAvaware(address address_) external onlyOwner {
        _avaware = IERC20(address_);
    }

    function setNeonMonsters(address address_) external onlyOwner {
        _neonMonsters = IERC721(address_);
    }

    function setNeonMonstersMinters(address address_) external onlyOwner {
        _neonMonstersMinters = INeonMonstersMinters(address_);
    }

    function getPrice(
        uint256 segmentNo,
        address sender,
        uint256 price,
        uint256 balance
    ) public view returns (uint256) {
        if (segmentNo == 0)
            return
                balance < (uint256(_neonMonsters.balanceOf(sender)) / 10) &&
                    _neonMonstersMinters.isMinter(sender)
                    ? price / 10
                    : price;

        if (segmentNo == 1)
            return
                balance == 0 && _neonMonsters.balanceOf(sender) >= 10
                    ? price - ((price / 100) * 30)
                    : price;

        if (segmentNo == 2)
            return
                balance == 0 && _avaware.balanceOf(sender) >= 10000 ether
                    ? price - ((price / 100) * 10)
                    : price;

        return price;
    }
}