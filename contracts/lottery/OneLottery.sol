// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OneLottery is Ownable {
    // Participants
    address payable[] private _participants;

    // Total prize
    uint256 public prize;

    // Ticket fee
    uint256 private _fee;

    // Max ticket limit per transaction
    uint256 public constant MAX_TICKET_PER_TX = 30;

    // Represents the lottery status
    enum State {
        OPEN, // Lottery started
        CLOSED // Lottery closed
    }

    // Lottery status
    State public lotteryState;

    // Mapping from participant to ticket count
    mapping(address => uint256) public tickets;

    event Winner(address indexed winner);

    /**
     * @dev Initializes the contract.
     *
     * @param fee_ The lottery ticket fee.
     */
    constructor(uint256 fee_) {
        _fee = fee_;
        lotteryState = State.CLOSED;
    }

    /**
     * @dev Starts the lottery.
     *
     * Requirements:
     *
     * - Only owner can start the lottery.
     * - `lotteryState` must be `State.OPEN`.
     * - Ether value sent is must higher than 1 ether.
     */
    function start() public payable onlyOwner {
        require(
            lotteryState == State.CLOSED,
            "Lottery: lottery state is not open"
        );
        require(
            msg.value >= 1 ether,
            "Lottery: ether value sent is not correct"
        );

        lotteryState = State.OPEN;
        prize = msg.value;
    }

    /**
     * @dev Participate in the lottery.
     *
     * @param numberOfTickets The ticket number.
     *
     * Requirements:
     *
     * - `numberOfTickets` must be equal or lower than the max ticket purchase limit.
     * - `lotteryState` must be `State.OPEN`.
     * - `numberOfTickets` must be higher than zero.
     * - Caller must be wallet address.
     * - Ether value sent is must be equal or higher than the fees.
     */
    function participate(uint256 numberOfTickets) external payable {
        require(
            numberOfTickets <= MAX_TICKET_PER_TX,
            "Lottery: maximum ticket purchase exceeds"
        );
        require(
            lotteryState == State.OPEN,
            "Lottery: lottery state is not open"
        );
        require(numberOfTickets > 0, "Lottery: zero ticket");
        require(!Address.isContract(_msgSender()), "Lottery: conract call");

        uint256 amountTopay = numberOfTickets * _fee;

        require(msg.value >= amountTopay);

        for (uint256 i = 0; numberOfTickets > i; i++) {
            tickets[_msgSender()] += 1;
            _participants.push(payable(_msgSender()));
        }

        prize += amountTopay;
    }

    /**
     * @dev Finalize the lottery, and destroy the contract.
     *
     * @param seed The seed to create random number.
     *
     * Requirements:
     *
     * - `lotteryState` must be `State.OPEN`.
     * - `_participants.length` must be greater than zero.
     *
     */
    function finalize(uint256 seed) public onlyOwner {
        require(
            lotteryState == State.OPEN,
            "Lottery: lottery state is not open"
        );

        lotteryState = State.CLOSED;

        require(_participants.length > 0, "Lottery: no participant");
        uint256 indexOf = _psuedoRandom(seed) % _participants.length;

        address payable winner = _participants[indexOf];
        Address.sendValue(winner, prize);

        emit Winner(winner);

        selfdestruct(payable(owner()));
    }

    /**
     * @return The length of participants.
     */
    function lengthOf() external view returns (uint256) {
        return _participants.length;
    }

    /**
     * @return The fee.
     */
    function fee() external view returns (uint256) {
        return _fee;
    }

    /**
     * @dev Generate random number, based on the given seed number.
     *
     * @return Random number.
     */
    function _psuedoRandom(uint256 seed) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        block.difficulty,
                        _participants.length,
                        seed
                    )
                )
            );
    }
}
