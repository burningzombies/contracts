// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title PaymentSplitter contract.
/// @author OpenZeppelin Contracts v4.4.0 (finance/PaymentSplitter.sol)
/// @author root36x9
contract PaymentSplitter is Ownable, Pausable {
    /// @dev Emitted when new payee is added.
    /// @param account Payee's account.
    /// @param shares Payee's shares.
    event PayeeAdded(address account, uint256 shares);

    /// @dev Emitted when new a payment released by a payee.
    /// @param to Payment sent to this address.
    /// @param amount The amount of payment.
    event PaymentReleased(address to, uint256 amount);

    /// @dev Emitted when payment received.
    /// @param from The address Ethers came from.
    /// @param amount Received amount.
    event PaymentReceived(address from, uint256 amount);

    /// @dev Sum of shares.
    uint256 private _totalShares;

    /// @dev Sum of released amount.
    uint256 private _totalReleased;

    /// @dev Mapping for payees to shares.
    mapping(address => uint256) private _shares;

    /// @dev Mapiing for payees to released amounts.
    mapping(address => uint256) private _released;

    /// @dev Payee addresses.
    address[] private _payees;

    /// @param payees   Payee addresses.
    /// @param shares_  Shares for the payees.
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /// @dev Emits `PaymentReceived` event when the ether received.
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /// @dev Getter for the total shares held by payees.
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /// @dev Getter for the total amount of Ether already released.
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /// @dev Getter for the amount of shares held by an account.
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /// @dev Getter for the amount of Ether already released to a payee.
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /// @dev Getter for the address of the payee number `index`.
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /// @dev Getter for the pending amount held by an account.
    function pendingPayment(address account) external view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /// @param account  The address to transfer owed amount.
    function release(address payable account) public virtual whenNotPaused {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /// @param account          The account to calculate owed amount.
    /// @param totalReceived    Total received amount to the contract.
    /// @param alreadyReleased  Released amount for the given account.
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /// @param account  The address of the payee to add.
    /// @param shares_  The number of shares owned by the payee.
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /// @dev Recover Ethers when contract paused.
    function withdraw(address payable recipient) external onlyOwner {
        Address.sendValue(recipient, address(this).balance);
    }

    /// @dev Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}
