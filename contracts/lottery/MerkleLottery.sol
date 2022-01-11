// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleLottery contract.
/// @author root36x9
contract MerkleLottery is Ownable {
    /// @dev Participants
    address payable[] private _participants;

    /// @dev The winner
    address payable private _winner;

    /// @dev Total prize
    uint256 public prize;

    /// @dev Ticket fee
    uint256 private _fee;

    /// @dev Max ticket limit per transaction
    uint256 public constant MAX_TICKET_PER_TX = 30;

    /// @dev Merkle root.
    bytes32 public immutable merkleRoot;

    /// @dev Represents the lottery status
    enum State {
        OPEN, // Lottery started
        CLOSED // Lottery closed
    }

    /// @dev Lottery status
    State public lotteryState;

    /// @dev Mapping from participant to ticket count
    mapping(address => uint256) public tickets;

    /// @dev Emitted when winner is picked.
    event Winner(address indexed winner);

    /// @dev Initializes the contract.
    /// @param fee_ The lottery ticket fee.
    /// @param merkleRoot_ Merkle root.
    constructor(uint256 fee_, bytes32 merkleRoot_) {
        _fee = fee_;
        lotteryState = State.CLOSED;
        merkleRoot = merkleRoot_;
    }

    /// @dev Starts the lottery.
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

    /// @dev Participate in the lottery.
    /// @param numberOfTickets The ticket number.
    /// @param merkleProof Proof.
    function participate(
        uint256 numberOfTickets,
        bytes32[] calldata merkleProof
    ) external payable {
        require(
            lotteryState == State.OPEN,
            "Lottery: lottery state is not open"
        );
        require(numberOfTickets > 0, "Lottery: zero ticket");
        require(!Address.isContract(_msgSender()), "Lottery: conract call");

        bytes32 leaf = keccak256(
            abi.encodePacked(_msgSender(), numberOfTickets)
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "Lottery: Valid proof required.");

        uint256 amountTopay = numberOfTickets * _fee;

        require(msg.value >= amountTopay);

        for (uint256 i = 0; numberOfTickets > i; i++) {
            tickets[_msgSender()] += 1;
            _participants.push(payable(_msgSender()));
        }

        prize += amountTopay;
    }

    /// @dev Finalize the lottery, and destroy the contract.
    /// @param seed The seed to create random number.
    function finalize(uint256 seed) public onlyOwner {
        require(
            lotteryState == State.OPEN,
            "Lottery: lottery state is not open"
        );

        lotteryState = State.CLOSED;

        require(_participants.length > 0, "Lottery: no participant");
        uint256 indexOf = _psuedoRandom(seed) % _participants.length;

        _winner = _participants[indexOf];
        Address.sendValue(_winner, prize);

        emit Winner(_winner);
    }

    /// @dev Getter for the winner address.
    function winner() external view returns (address) {
        return _winner;
    }

    /// @return The length of participants.
    function lengthOf() external view returns (uint256) {
        return _participants.length;
    }

    /// @return The fee.
    function fee() external view returns (uint256) {
        return _fee;
    }

    /// @dev Generate random number, based on the given seed number.
    /// @param seed Seed.
    /// @return Random number.
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
