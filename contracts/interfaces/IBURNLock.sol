// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBURNLock {
    /// @dev Timestamp for the begining of the claiming.
    function unlockBegin() external view returns (uint256);

    /// @dev Timestamp for the first time at which tokens are claimable.
    function unlockCliff() external view returns (uint256);

    /// @dev Timestamp for the last unlock.
    function unlockEnd() external view returns (uint256);

    /// @dev Mapping from address to locked amounts.
    function lockedAmounts(address address_) external view returns (uint256);

    /// @dev Mapping from address to claimed amounts.
    function claimedAmounts(address address_) external view returns (uint256);

    /// @dev Locked token address.
    function token() external view returns (IERC20);

    /// @dev Transfers tokens from the caller to the token lock contract and locks them for benefit of `recipient`.
    ///      Requires that the caller has authorised this contract with the token contract.
    /// @param recipient The account the tokens will be claimable by.
    /// @param amount The number of tokens to transfer and lock.
    function lock(address recipient, uint256 amount) external;

    /// @dev Claims the caller's tokens that have been unlocked, sending them to `recipient`.
    /// @param recipient The account to transfer unlocked tokens to.
    /// @param amount The amount to transfer. If greater than the claimable amount, the maximum is transferred.
    function claim(address recipient, uint256 amount) external;

    /// @dev Returns the maximum number of tokens currently claimable by `owner`.
    /// @param owner The account to check the claimable balance of.
    /// @return The number of tokens currently claimable.
    function claimableBalance(address owner) external view returns (uint256);
}
