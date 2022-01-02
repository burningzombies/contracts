// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPriceCalculator.sol";

contract BurningZombiesERC721 is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    /* ========== STATE VARIABLES ========== */

    uint256 public constant MAX_SUPPLY = 3024;
    uint256 public constant MAX_TOKEN_PER_TX = 24;
    uint256 public constant MAX_TOKEN_PER_WALLET = 100;

    uint256 public segmentSize;
    uint256 public reflectionBase;
    uint256 public reflectionStep;
    uint256 public priceBase;
    uint256 public priceStep;

    string public provenance;

    uint256 public saleStartsAt;
    uint256 public saleDuration;

    uint256 public reflectionBalance;
    uint256 public totalDividend;
    uint256 public burnedReflectionBalance;

    string private _baseURIextended;
    Counters.Counter private _tokenIdCounter;
    address private _splitter;
    IPriceCalculator private _priceCalculator;

    mapping(uint256 => uint256) private _lastDividendAt;
    mapping(uint256 => address) private _minters;

    event BurnedReflectionDivided(
        address indexed user,
        uint256 indexed tokenId
    );

    /* ========== CONSTRUCTOR ========== */

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
        reflectionBase = 30;
        reflectionStep = 0;
        priceBase = 1.5 ether;
        priceStep = 0;
    }

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

        if (!(MAX_TOKEN_PER_WALLET > balanceOf(to)))
            revert(
                "BurningZombiesERC721: the receiver exceeds max holding amount"
            );

        if (from == address(0) || from == owner()) {
            super._beforeTokenTransfer(from, to, tokenId);
            return;
        }

        claimReward(tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /* ========== VIEWS ========== */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function currentTokenPrice() public view returns (uint256) {
        return _tokenPrice(_tokenIdCounter.current());
    }

    function tokenPrice(uint256 tokenId) public view returns (uint256) {
        require(
            tokenId >= 0 && tokenId < MAX_SUPPLY,
            "BurningZombiesERC721: invalid range"
        );

        return _tokenPrice(tokenId);
    }

    function isSaleActive() public view returns (bool) {
        return
            block.timestamp >= saleStartsAt &&
            block.timestamp <= (saleStartsAt + saleDuration) &&
            _tokenIdCounter.current() < MAX_SUPPLY;
    }

    function minterOf(uint256 tokenId) external view returns (address) {
        require(
            _exists(tokenId),
            "BurningZombiesERC721: token does not exists"
        );

        return _minters[tokenId];
    }

    function currentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function calculateReflectionShare() public view returns (uint256) {
        if (!(_tokenIdCounter.current() > 1)) return reflectionBase;

        return
            reflectionBase +
            ((_tokenIdCounter.current() - 1) / segmentSize) *
            reflectionStep;
    }

    function getReflectionBalances() public view returns (uint256) {
        uint256 count = balanceOf(_msgSender());
        uint256 total = 0;

        for (uint256 i = 0; count > i; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            total += getReflectionBalance(tokenId);
        }

        return total;
    }

    function getReflectionBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (!_exists(tokenId)) return 0;

        return totalDividend - _lastDividendAt[tokenId];
    }

    /* ========== GOVERNOR FUNCTIONS ========== */

    function mintTokensByOwner(uint256 numberOfTokens, address to)
        external
        payable
        onlyOwner
    {
        require(isSaleActive(), "BurningZombiesERC721: sale is not active");

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

    function setReflectionDynamics(
        uint256 segmentSize_,
        uint256 reflectionBase_,
        uint256 reflectionStep_,
        uint256 priceBase_,
        uint256 priceStep_
    ) public onlyOwner {
        require(
            _tokenIdCounter.current() == 0,
            "BurningZombiesERC721: first token already minted"
        );

        segmentSize = segmentSize_;
        reflectionBase = reflectionBase_;
        reflectionStep = reflectionStep_;
        priceBase = priceBase_;
        priceStep = priceStep_;
    }

    function setPriceCalculator(address address_) external onlyOwner {
        _priceCalculator = IPriceCalculator(address_);
    }

    function setMintingSharesSplitter(address address_) external onlyOwner {
        _splitter = address_;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIextended = baseURI;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function setSaleStart(uint256 timestamp) external onlyOwner {
        saleStartsAt = timestamp;
    }

    function setSaleDuration(uint256 duration) external onlyOwner {
        saleDuration = duration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mintTokens(uint256 numberOfTokens) external payable {
        require(isSaleActive(), "BurningZombiesERC721: sale is not active");

        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_TOKEN_PER_TX,
            "BurningZombiesERC721: purchase exceeds max limit per transaction"
        );

        require(
            _tokenIdCounter.current() + numberOfTokens <= MAX_SUPPLY,
            "BurningZombiesERC721: purchase exceeds max supply of tokens"
        );

        uint256 amountToPay;
        for (uint256 i = 0; numberOfTokens > i; i++) {
            amountToPay += _tokenPrice(_tokenIdCounter.current() + i);
        }

        require(
            msg.value >= amountToPay,
            "BurningZombiesERC721: ether value sent is not correct"
        );

        _mintTokens(numberOfTokens, _msgSender());

        _splitBalance(amountToPay);
    }

    function divideUnclaimedTokenReflection(uint256 numberOfTokens) public {
        require(
            _tokenIdCounter.current() + numberOfTokens <= MAX_SUPPLY,
            "BurningZombiesERC721: burning exceeds max supply of tokens"
        );

        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_TOKEN_PER_TX,
            "BurningZombiesERC721: burning exceeds max limit per transaction"
        );

        require(!isSaleActive(), "BurningZombiesERC721: sale is active");

        for (uint256 i = 0; numberOfTokens > i; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            totalDividend += burnedReflectionBalance / totalSupply();

            emit BurnedReflectionDivided(_msgSender(), tokenId);
        }
    }

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

    /* ========== HELPER FUNCTIONS ========== */

    function _mintTokens(uint256 numberOfTokens, address to) private {
        for (uint256 i = 0; numberOfTokens > i; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint(to, tokenId);
            _minters[tokenId] = to;
            _lastDividendAt[tokenId] = 0;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _tokenPrice(uint256 tokenId) private view returns (uint256) {
        uint256 segmentNo = uint256(uint256(tokenId) / uint256(segmentSize));
        address sender = _msgSender();
        uint256 price = (segmentNo * priceStep) + priceBase;
        uint256 balance = balanceOf(sender);

        return _priceCalculator.getPrice(segmentNo, sender, price, balance);
    }

    function _splitBalance(uint256 amount) private nonReentrant {
        uint256 reflectionShare = (amount / 100) * calculateReflectionShare();
        uint256 mintingShare = amount - reflectionShare;

        _reflectDividend(reflectionShare);

        address payable recipient = payable(_splitter);
        Address.sendValue(recipient, mintingShare);
    }

    function _reflectDividend(uint256 amount) private {
        reflectionBalance += amount;
        totalDividend += (amount / MAX_SUPPLY);
        burnedReflectionBalance = totalDividend;
    }
}
