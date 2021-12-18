// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] private _participants;
    address payable private _winner;

    bytes32 internal _keyHash;
    bytes32 internal _requestId;
    uint256 internal _fee;

    uint256 public prize;

    uint256 public randomResult;

    enum State {
        OPEN,
        CLOSED,
        PROCESSING
    }

    State public lotteryState;

    mapping(address => bool) private _uniqueAddresses;

    constructor(
        bytes32 keyHash_,
        uint256 fee_,
        address vrfCoordinator_,
        address link_
    ) VRFConsumerBase(vrfCoordinator_, link_) {
        lotteryState = State.CLOSED;
        _keyHash = keyHash_;
        _fee = fee_;
    }

    function join() external {
        require(lotteryState == State.OPEN, "Lottery: no active lottery");
        require(
            _uniqueAddresses[_msgSender()] == false,
            "Lottery: already joined"
        );

        lotteryState = State.OPEN;
        _uniqueAddresses[_msgSender()] = true;
        _addParticipant(payable(_msgSender()));
    }

    function start() public payable onlyOwner {
        require(
            lotteryState == State.CLOSED,
            "Lottery: there is active lottery"
        );
        lotteryState = State.OPEN;
        prize = msg.value;
    }

    function end() public onlyOwner {
        lotteryState = State.PROCESSING;
        _requestId = requestRandomness(_keyHash, _fee);
    }

    function lenghtOf() public view returns (uint256) {
        return _participants.length;
    }

    function winner() external view returns (address) {
        return _winner;
    }

    // solhint-disable-next-line
    function fulfillRandomness(bytes32 requestId_, uint256 randomness_)
        internal
        override
    {
        require(
            lotteryState == State.PROCESSING,
            "Lottery: there is no finished lottery"
        );
        require(requestId_ == _requestId, "Lottery: request mismatch");
        require(randomness_ > 0, "Lottery: random not found");

        uint256 indexOf = randomness_ % lenghtOf();
        _winner = _participants[indexOf];
        randomResult = randomness_;
    }

    function finalize() public onlyOwner {
        address payable recipient = payable(_winner);
        Address.sendValue(recipient, prize);

        address payable destroyer = payable(owner());
        selfdestruct(destroyer);
    }

    function _addParticipant(address payable participant) private {
        _participants.push(participant);
    }
}
