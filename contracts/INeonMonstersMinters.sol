// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INeonMonstersMinters {
    function isMinter(address minter) external view returns (bool);
}
