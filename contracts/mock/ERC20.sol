// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(uint256 value) ERC20("ERC20 Mock", "ERC20MOCK") {
        _mint(msg.sender, value);
    }
}
