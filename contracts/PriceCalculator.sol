// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INeonMonstersMinters.sol";

/// @title PriceCalculator contract.
/// @author root36x9
contract PriceCalculator is Ownable {
    /// @dev Round type to determine token standard.
    enum Round {
        NFT,
        DEFI
    }

    /// @dev NeonMonstersMinters instance.
    INeonMonstersMinters private _neonMonstersMinters;

    /// @dev NeonMonsters instance.
    IERC721 private _neonMonsters;

    /// @dev ERC20 tokens to apply discount.
    IERC20[] private _erc20Tokens;

    /// @dev ERC721 tokens to apply discount.
    IERC721[] private _erc721Tokens;

    /// @dev Mapping from the token addresses to min hold amounts.
    mapping(address => uint256) private _minHoldingAmounts;

    /// @param address_     Token address to add discounted mapping state.
    /// @param min          Minimum hold amount for the given token address.
    function addERC20Token(IERC20 address_, uint256 min) external onlyOwner {
        _erc20Tokens.push(address_);
        _minHoldingAmounts[address(address_)] = min;
    }

    /// @param address_     Token address to add discounted mapping state.
    /// @param min          Minimum hold amount for the given token address.
    function addERC721Token(IERC721 address_, uint256 min) external onlyOwner {
        _erc721Tokens.push(address_);
        _minHoldingAmounts[address(address_)] = min;
    }

    /// @param address_     NeonMonstersMinters address.
    function setNeonMonstersMinters(INeonMonstersMinters address_)
        external
        onlyOwner
    {
        _neonMonstersMinters = address_;
    }

    /// @param segmentNo    Segment No; uint(tokenId / segmentSize)
    /// @param sender       Sender address.
    /// @param price        Base price.
    /// @param balance      Sender balance.
    /// @return             Current token price.
    function getPrice(
        uint256 segmentNo,
        address sender,
        uint256 price,
        uint256 balance
    ) public view returns (uint256) {
        if (segmentNo == 0) {
            if (
                balance <
                (uint256(IERC721(_erc721Tokens[0]).balanceOf(sender)) / 10) &&
                _neonMonstersMinters.isMinter(sender)
            ) return price / 10;
        }

        // NFT Round
        if (segmentNo > 0 && segmentNo < 5)
            return _roundPrice(Round.NFT, price, sender);

        // DeFi Round
        if (segmentNo > 4 && segmentNo < 9)
            return _roundPrice(Round.DEFI, price, sender);

        // fail safe
        return price;
    }

    /// @param round    Current round.
    /// @param price    Base price.
    /// @param sender   Sender address.
    /// @return         The current token price.
    function _roundPrice(
        Round round,
        uint256 price,
        address sender
    ) private view returns (uint256) {
        bool isEligible = false;

        if (round == Round.NFT) {
            for (uint256 i = 0; _erc721Tokens.length > i; i++) {
                if (
                    IERC721(_erc721Tokens[i]).balanceOf(sender) >=
                    _minHoldingAmounts[address(_erc721Tokens[i])]
                ) {
                    isEligible = true;
                    break;
                }
            }
        } else if (round == Round.DEFI) {
            for (uint256 i = 0; _erc20Tokens.length > i; i++) {
                if (
                    IERC20(_erc20Tokens[i]).balanceOf(sender) >=
                    _minHoldingAmounts[address(_erc20Tokens[i])]
                ) {
                    isEligible = true;
                    break;
                }
            }
        }

        if (isEligible) return price - ((price / 100) * 10);

        return price;
    }
}
