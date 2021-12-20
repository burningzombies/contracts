// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Lottery is Ownable {
    address payable[] private _participants;
    uint256 public prize;
    uint256 private _fee;

    enum State {
        OPEN,
        CLOSED
    }

    State public lotteryState;

    event Winner(address indexed winner);

    constructor(uint256 fee) {
        _fee = fee;
        lotteryState = State.CLOSED;
    }

    function start() public payable onlyOwner {
        require(lotteryState == State.CLOSED);
        require(msg.value >= 1 ether);

        lotteryState = State.OPEN;
        prize = msg.value;
    }

    function participate() public payable {
        require(lotteryState == State.OPEN);
        require(msg.value >= _fee);

        prize += msg.value;
        _addParticipate(_msgSender());
    }

    function finalize(uint256 seed) public onlyOwner {
        require(lotteryState == State.OPEN);
        uint256 indexOf = _psuedoRandom(seed) & _participants.length;

        address payable winner = _participants[indexOf];
        Address.sendValue(winner, prize);

        emit Winner(winner);

        selfdestruct(payable(owner()));
    }

    function _addParticipate(address participant) private {
        _participants.push(payable(participant));
    }

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

    function lengthOf() external view returns (uint256) {
        return _participants.length;
    }
}
