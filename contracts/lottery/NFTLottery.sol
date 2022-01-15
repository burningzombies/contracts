// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTLottery is Ownable, ERC721Holder {
    enum State {
        OPEN,
        CLOSED
    }

    address payable[] private _participants;
    address payable private _winner;
    uint256 public prizeTokenId;
    IERC721 public tokenAddress;
    uint256 private _fee;
    uint256 public constant MAX_TICKET_PER_TX = 30;
    State public lotteryState;

    mapping(address => uint256) public tickets;

    event Winner(address indexed winner);

    constructor(uint256 fee_) {
        _fee = fee_;
        lotteryState = State.CLOSED;
    }

    function start(IERC721 tokenAddress_, uint256 prizeTokenId_)
        public
        onlyOwner
    {
        require(
            lotteryState == State.CLOSED,
            "Lottery: lottery state is not open"
        );

        IERC721(tokenAddress_).safeTransferFrom(
            _msgSender(),
            address(this),
            prizeTokenId_
        );
        tokenAddress = tokenAddress_;
        prizeTokenId = prizeTokenId_;
        lotteryState = State.OPEN;
    }

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

        uint256 amountToPay = numberOfTickets * _fee;

        require(msg.value >= amountToPay);

        for (uint256 i = 0; numberOfTickets > i; i++) {
            tickets[_msgSender()] += 1;
            _participants.push(payable(_msgSender()));
        }

        Address.sendValue(
            payable(0xaBE94c96fd7C01Acaa312aeDC10e86828C65eC48),
            amountToPay
        );
    }

    function finalize(uint256 seed) public onlyOwner {
        require(
            lotteryState == State.OPEN,
            "Lottery: lottery state is not open"
        );

        lotteryState = State.CLOSED;

        require(_participants.length > 0, "Lottery: no participant");
        uint256 indexOf = _psuedoRandom(seed) % _participants.length;

        _winner = _participants[indexOf];

        IERC721(tokenAddress).safeTransferFrom(
            address(this),
            _winner,
            prizeTokenId
        );

        emit Winner(_winner);
    }

    function winner() external view returns (address) {
        return _winner;
    }

    function lengthOf() external view returns (uint256) {
        return _participants.length;
    }

    function fee() external view returns (uint256) {
        return _fee;
    }

    /// @dev Generate random number, based on the given seed number.
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
