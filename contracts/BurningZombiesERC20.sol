// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BurningZombiesERC20 is ERC20, ERC20Burnable {
    uint256 public constant TOTAL_SUPPLY = 24_000_000e18;

    constructor() ERC20("Burning Zombies", "ZOMBIE") {
        _mint(_msgSender(), TOTAL_SUPPLY);
    }
}
