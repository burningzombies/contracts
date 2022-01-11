// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBURNLock} from "./interfaces/IBURNLock.sol";

contract BurningZombiesERC20 is ERC20, ERC20Burnable, Ownable {
    uint256 public constant TOTAL_SUPPLY = 24_000_000e18;

    /// @dev 50%
    uint256 public constant STAKING_SUPPLY = (TOTAL_SUPPLY / 100) * 50;

    /// @dev 40%
    uint256 public constant LIQ_SUPPLY = (TOTAL_SUPPLY / 100) * 40;

    /// @dev 10%
    uint256 public constant DEV_SUPPLY = (TOTAL_SUPPLY / 100) * 10;

    bool public isVested;

    constructor(address stakingAddress, address liqAddress)
        ERC20("Burn", "BURN")
    {
        _mint(stakingAddress, STAKING_SUPPLY);
        _mint(address(this), DEV_SUPPLY);
        _mint(liqAddress, LIQ_SUPPLY);
    }

    /// @dev Start vest for the team.
    /// @param lockAddress Token lock address.
    function startVest(IBURNLock lockAddress) public onlyOwner {
        require(!isVested, "BurningZombiesERC20: Vest has already started.");
        isVested = true;

        address x = 0xF4E27CF0b142EbAE5878942a82ef7c6d3496285e; // 50%
        address y = 0x27BcCc0cEFa040747c80e52AeDd6dBb64f19083c; // 50%

        _approve(address(this), address(lockAddress), DEV_SUPPLY);
        IBURNLock(lockAddress).lock(x, (DEV_SUPPLY / 100) * 50);
        IBURNLock(lockAddress).lock(y, (DEV_SUPPLY / 100) * 50);
    }
}
