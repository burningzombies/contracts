// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Avaware is ERC20 {
    constructor() ERC20("Avaware Mock", "AVAWAREMOCK") {
        _mint(msg.sender, 1000000 ether);
    }
}
