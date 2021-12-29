// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IPriceCalculator {
    function getPrice(
        uint256 segmentNo,
        address sender,
        uint256 basePrice,
        uint256 balance
    ) external view returns (uint256);
}
