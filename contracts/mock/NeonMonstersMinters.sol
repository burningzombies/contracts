// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NeonMonstersMinters is Ownable {
    mapping(address => bool) private _minters;

    function isMinter(address minter) public view returns (bool) {
        if (_minters[minter] == true) return true;
        return false;
    }

    function setMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }

    function delMinter(address minter) public onlyOwner {
        _minters[minter] = false;
    }
}
