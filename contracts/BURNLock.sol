// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBURNLock} from "./interfaces/IBURNLock.sol";

/// @dev Time-locks tokens according to an unlock schedule.
/// @title BURNLock contract.
/// @author root36x9
contract BURNLock is IBURNLock {
    /// @inheritdoc IBURNLock
    IERC20 public immutable override token;

    /// @inheritdoc IBURNLock
    uint256 public immutable override unlockBegin;

    /// @inheritdoc IBURNLock
    uint256 public immutable override unlockCliff;

    /// @inheritdoc IBURNLock
    uint256 public immutable override unlockEnd;

    /// @inheritdoc IBURNLock
    mapping(address => uint256) public override lockedAmounts;

    /// @inheritdoc IBURNLock
    mapping(address => uint256) public override claimedAmounts;

    /// @dev Emitted when the tokens locked to and address.
    /// @param sender The account who is locked.
    /// @param recipient The account the tokens will be claimable by.
    /// @param amount The number of tokens to transfer and lock.
    event Locked(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Emitted when the tokens claimed..
    /// @param owner Owner of the tokens..
    /// @param recipient Recipient for the locked tokens.
    /// @param amount The number of tokens to transfer and lock.
    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Constructor.
    /// @param _token The token this contract will lock.l
    /// @param _unlockBegin The time at which unlocking of tokens will begin.
    /// @param _unlockCliff The first time at which tokens are claimable.
    /// @param _unlockEnd The time at which the last token will unlock.
    constructor(
        IERC20 _token,
        uint256 _unlockBegin,
        uint256 _unlockCliff,
        uint256 _unlockEnd
    ) {
        require(
            _unlockCliff >= _unlockBegin,
            "BURNLocked: Unlock cliff must not be before unlock begin"
        );
        require(
            _unlockEnd >= _unlockCliff,
            "BURNLocked: Unlock end must not be before unlock cliff"
        );
        token = _token;
        unlockBegin = _unlockBegin;
        unlockCliff = _unlockCliff;
        unlockEnd = _unlockEnd;
    }

    /// @inheritdoc IBURNLock
    function claimableBalance(address owner)
        public
        view
        override
        returns (uint256)
    {
        if (block.timestamp < unlockCliff) {
            return 0;
        }

        uint256 locked = lockedAmounts[owner];
        uint256 claimed = claimedAmounts[owner];
        if (block.timestamp >= unlockEnd) {
            return locked - claimed;
        }
        return
            (locked * (block.timestamp - unlockBegin)) /
            (unlockEnd - unlockBegin) -
            claimed;
    }

    /// @inheritdoc IBURNLock
    function lock(address recipient, uint256 amount) public override {
        require(
            block.timestamp < unlockEnd,
            "TokenLock: Unlock period already complete"
        );
        lockedAmounts[recipient] += amount;
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "TokenLock: Transfer failed"
        );
        emit Locked(msg.sender, recipient, amount);
    }

    /// @inheritdoc IBURNLock
    function claim(address recipient, uint256 amount) public override {
        uint256 claimable = claimableBalance(msg.sender);
        if (amount > claimable) {
            amount = claimable;
        }
        claimedAmounts[msg.sender] += amount;
        require(
            IERC20(token).transfer(recipient, amount),
            "TokenLock: Transfer failed"
        );
        emit Claimed(msg.sender, recipient, amount);
    }
}
