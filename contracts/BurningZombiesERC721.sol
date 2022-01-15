// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPriceCalculator} from "./interfaces/IPriceCalculator.sol";

/// @title BurningZombiesERC721
/// @author root36x9
contract BurningZombiesERC721 is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    /// @dev Maximum supply.
    uint256 public constant MAX_SUPPLY = 3024;

    /// @dev Maximum token amount to transfer.
    uint256 public constant MAX_TOKEN_PER_TX = 24;

    /// @dev Maximum holding amount.
    uint256 public constant MAX_TOKEN_PER_WALLET = 100;

    /// @dev The segment size of the collection.
    uint256 public segmentSize;

    /// @dev Reflection base.
    uint256 public reflectionBase;

    /// @dev Reflection step.
    uint256 public reflectionStep;

    /// @dev Price base.
    uint256 public priceBase;

    /// @dev Price step.
    uint256 public priceStep;

    /// @dev Provenance hash of the hashed string of the hashed images.
    string public provenance;

    /// @dev Sale timestamp.
    uint256 public saleStartsAt;

    /// @dev Sale duration timestamp.
    uint256 public saleDuration;

    /// @dev Sum of the reflections.
    uint256 public reflectionBalance;

    /// @dev Amount of reflection per token owner.
    uint256 public totalDividend;

    /// @dev Sum of the reflections of the not minted tokens.
    uint256 public burnedReflectionBalance;

    /// @dev Base URI for the tokens' metadata.
    string private _baseURIextended;

    /// @dev Token Id tracker.
    Counters.Counter private _tokenIdCounter;

    /// @dev Slitter contract instance to collect minting fees.
    address private _splitter;

    /// @dev Instance of the price calculator contract.
    IPriceCalculator private _priceCalculator;

    /// @dev Mapping from token ID to last claimed amount.
    mapping(uint256 => uint256) private _lastDividendAt;

    /// @dev Mapping from token ID to the first owner's address.
    mapping(uint256 => address) private _minters;

    /// @dev Mapping from the address to approval
    mapping(address => bool) private _whitelistHolders;

    /// @dev Emitted when unminted tokens' reflected.
    /// @param user Sender.
    /// @param tokenId The ghost token id.
    event BurnedReflectionDivided(
        address indexed user,
        uint256 indexed tokenId
    );

    /// @param splitter_ Splitter contract instance.
    /// @param baseURI Base URI.
    /// @param start Timestamp for sale's start.
    /// @param duration Duration.
    constructor(
        address splitter_,
        string memory baseURI,
        uint256 start,
        uint256 duration
    ) ERC721("Burning Zombies", "ZOMBIE") {
        _splitter = splitter_;

        _baseURIextended = baseURI;
        saleStartsAt = start;
        saleDuration = duration;

        segmentSize = 336;
        reflectionBase = 15;
        reflectionStep = 0;
        priceBase = 2 ether;
        priceStep = 0;

        _whitelistHolders[owner()] = true;
        _whitelistHolders[address(0)] = true;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        if (to == address(0)) {
            claimReward(tokenId);

            delete _minters[tokenId];
            delete _lastDividendAt[tokenId];

            super._beforeTokenTransfer(from, to, tokenId);
            return;
        }

        if (
            _whitelistHolders[to] == false &&
            !(MAX_TOKEN_PER_WALLET > balanceOf(to))
        )
            revert(
                "BurningZombiesERC721: the receiver exceeds max holding amount"
            );

        if (_whitelistHolders[from] == true || _whitelistHolders[to] == true) {
            super._beforeTokenTransfer(from, to, tokenId);
            return;
        }

        claimReward(tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Getter for the current token price.
    function currentTokenPrice() public view returns (uint256) {
        return _tokenPrice(_tokenIdCounter.current());
    }

    /// @dev Getter for the token price by given token id.
    /// @param tokenId Token ID
    function tokenPrice(uint256 tokenId) public view returns (uint256) {
        require(
            tokenId >= 0 && tokenId < MAX_SUPPLY,
            "BurningZombiesERC721: invalid range"
        );

        return _tokenPrice(tokenId);
    }

    /// @dev Getter for status of the sale.
    function isSaleActive() public view returns (bool) {
        return
            block.timestamp >= saleStartsAt &&
            block.timestamp <= (saleStartsAt + saleDuration) &&
            _tokenIdCounter.current() < MAX_SUPPLY;
    }

    /// @dev The first buyer of the given token id.
    /// @param tokenId Token ID
    function minterOf(uint256 tokenId) external view returns (address) {
        require(
            _exists(tokenId),
            "BurningZombiesERC721: token does not exists"
        );

        return _minters[tokenId];
    }

    /// @dev Getter for the token id tracker.
    function currentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @dev Calculates the reflection share.
    function calculateReflectionShare() public view returns (uint256) {
        if (!(_tokenIdCounter.current() > 1)) return reflectionBase;

        return
            reflectionBase +
            ((_tokenIdCounter.current() - 1) / segmentSize) *
            reflectionStep;
    }

    /// @dev Getter for the reflection balance.
    function getReflectionBalances() public view returns (uint256) {
        uint256 count = balanceOf(_msgSender());
        uint256 total = 0;

        for (uint256 i = 0; count > i; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            total += getReflectionBalance(tokenId);
        }

        return total;
    }

    /// @dev Getter for the reflection balance by given token id.
    /// @param tokenId Token ID
    function getReflectionBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (!_exists(tokenId)) return 0;

        return totalDividend - _lastDividendAt[tokenId];
    }

    /// @dev Mint functionality for the owner.
    /// @param numberOfTokens Number of tokens to mint.
    /// @param to Address to mint.
    function mintTokens(uint256 numberOfTokens, address to)
        external
        payable
        onlyOwner
    {
        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_TOKEN_PER_TX,
            "BurningZombiesERC721: purchase exceeds max limit per transaction"
        );

        require(
            _tokenIdCounter.current() + numberOfTokens <= MAX_SUPPLY,
            "BurningZombiesERC721: purchase exceeds max supply of tokens"
        );

        _mintTokens(numberOfTokens, to);

        _splitBalance(msg.value);
    }

    /// @dev Setter for the address. (Stake contract)
    function setWhitelistHolder(address account, bool approved)
        external
        onlyOwner
    {
        _whitelistHolders[account] = approved;
    }

    /// @dev Update reflection dynamics before sale start.
    /// @param segmentSize_ Segment size.
    /// @param reflectionBase_ Reflection base.
    /// @param reflectionStep_ Reflection step.
    /// @param priceBase_ Price base.
    /// @param priceStep_ Price step.
    function setReflectionDynamics(
        uint256 segmentSize_,
        uint256 reflectionBase_,
        uint256 reflectionStep_,
        uint256 priceBase_,
        uint256 priceStep_
    ) public onlyOwner {
        segmentSize = segmentSize_;
        reflectionBase = reflectionBase_;
        reflectionStep = reflectionStep_;
        priceBase = priceBase_;
        priceStep = priceStep_;
    }

    /// @dev Setter for the PriceCalculator contract.
    /// @param address_ Address of the contract.
    function setPriceCalculator(address address_) external onlyOwner {
        _priceCalculator = IPriceCalculator(address_);
    }

    /// @dev Setter for the PaymentSplitter contract.
    /// @param address_ Address of the contract.
    function setMintingSharesSplitter(address address_) external onlyOwner {
        _splitter = address_;
    }

    /// @dev Setter for the tokens' metadata.
    /// @param baseURI Base URI.
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIextended = baseURI;
    }

    /// @dev Setter for the provanance hash.
    /// @param provenance_ Hash.
    function setProvenance(string memory provenance_) public onlyOwner {
        provenance = provenance_;
    }

    /// @dev Setter for the sale.
    /// @param timestamp Start timestamp.
    function setSaleStart(uint256 timestamp) external onlyOwner {
        saleStartsAt = timestamp;
    }

    /// @dev Setter for the sale duration.
    /// @param duration Duration.
    function setSaleDuration(uint256 duration) external onlyOwner {
        saleDuration = duration;
    }

    /// @dev Mint by users.
    function mint() external payable {
        require(isSaleActive(), "BurningZombiesERC721: sale is not active");

        require(
            _tokenIdCounter.current() < MAX_SUPPLY,
            "BurningZombiesERC721: purchase exceeds max supply of tokens"
        );

        uint256 amountToPay = _tokenPrice(_tokenIdCounter.current());

        require(
            msg.value >= amountToPay,
            "BurningZombiesERC721: ether value sent is not correct"
        );

        _mintTokens(1, _msgSender());

        _splitBalance(amountToPay);
    }

    /// @dev Reflect unminted tokens after mint.
    /// @param numberOfTokens Number of the tokens for the loop.
    function divideUnclaimedTokenReflection(uint256 numberOfTokens) public {
        require(
            _tokenIdCounter.current() + numberOfTokens <= MAX_SUPPLY,
            "BurningZombiesERC721: burning exceeds max supply of tokens"
        );

        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_TOKEN_PER_TX,
            "BurningZombiesERC721: burning exceeds max limit per transaction"
        );

        require(
            block.timestamp >= saleStartsAt,
            "BurningZombiesERC721: sale is not started yet."
        );
        require(!isSaleActive(), "BurningZombiesERC721: sale is active");

        for (uint256 i = 0; numberOfTokens > i; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            totalDividend += burnedReflectionBalance / totalSupply();

            emit BurnedReflectionDivided(_msgSender(), tokenId);
        }
    }

    /// @dev Claims the fiven token's reflected amounts.
    /// @param tokenId Token ID.
    function claimReward(uint256 tokenId) public nonReentrant {
        require(!isSaleActive(), "BurningZombiesERC721: sale is active");

        require(
            _tokenIdCounter.current() >= MAX_SUPPLY,
            "BurningZombiesERC721: there are unclaimed or not burned tokens"
        );

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "BurningZombiesERC721: claim reward caller is not owner nor approved"
        );

        uint256 balance = getReflectionBalance(tokenId);
        Address.sendValue(payable(ownerOf(tokenId)), balance);
        _lastDividendAt[tokenId] = totalDividend;
    }

    /// @dev Claims all reflected amounts from sender's tokens.
    function claimRewards() public nonReentrant {
        require(!isSaleActive(), "BurningZombiesERC721: sale is active");

        require(
            _tokenIdCounter.current() >= MAX_SUPPLY,
            "BurningZombiesERC721: there are unclaimed or not burned tokens"
        );

        uint256 count = balanceOf(_msgSender());
        uint256 balance = 0;

        for (uint256 i = 0; count > i; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            balance += getReflectionBalance(tokenId);
            _lastDividendAt[tokenId] = totalDividend;
        }

        Address.sendValue(payable(_msgSender()), balance);
    }

    /// @param numberOfTokens Number of the tokens.
    /// @param to Account to mint.
    function _mintTokens(uint256 numberOfTokens, address to) private {
        for (uint256 i = 0; numberOfTokens > i; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint(to, tokenId);
            _minters[tokenId] = to;
            _lastDividendAt[tokenId] = 0;
        }
    }

    /// @dev Override base URI getter.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /// @dev Fetch the price for the given token id.
    /// @param tokenId Token ID.
    function _tokenPrice(uint256 tokenId) private view returns (uint256) {
        uint256 segmentNo = uint256(uint256(tokenId) / uint256(segmentSize));
        address sender = _msgSender();
        uint256 price = (segmentNo * priceStep) + priceBase;
        uint256 balance = balanceOf(sender);

        return _priceCalculator.getPrice(segmentNo, sender, price, balance);
    }

    /// @dev Split balance between payees.
    /// @param amount Splitted amount.
    function _splitBalance(uint256 amount) private nonReentrant {
        uint256 reflectionShare = (amount / 100) * calculateReflectionShare();
        uint256 mintingShare = amount - reflectionShare;

        _reflectDividend(reflectionShare);

        address payable recipient = payable(_splitter);
        Address.sendValue(recipient, mintingShare);
    }

    /// @dev Distributes the given amount to the community.
    /// @param amount The amount to the distribute.
    function _reflectDividend(uint256 amount) private {
        reflectionBalance += amount;
        totalDividend += (amount / MAX_SUPPLY);
        burnedReflectionBalance = totalDividend;
    }
}
