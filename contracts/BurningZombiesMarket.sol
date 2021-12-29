//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IBurningZombiesERC721.sol";

contract BurningZombiesMarket is Ownable, Pausable, ReentrancyGuard {
    event Sale(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    event ListingCreated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );
    event ListingCancelled(uint256 indexed tokenId);

    IBurningZombiesERC721 private _masterContract;

    uint256 private _minterRoyalty;
    uint256 private _reflectionRoyalty;
    uint256 private _devRoyalty;

    uint256 public reflectionBalance;
    uint256 public totalDividend;
    mapping(uint256 => uint256) private _lastDividendAt;

    struct Listing {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 price;
        bool exists;
    }

    mapping(uint256 => Listing) private _listings;

    constructor(
        address masterContractAddress,
        uint256 devRoyalty,
        uint256 minterRoyalty,
        uint256 reflectionRoyalty
    ) {
        _masterContract = IBurningZombiesERC721(masterContractAddress);
        _minterRoyalty = minterRoyalty;
        _devRoyalty = devRoyalty;
        _reflectionRoyalty = reflectionRoyalty;
        _pause();
    }

    modifier isTokenOwner(uint256 tokenId) {
        address caller = _masterContract.ownerOf(tokenId);
        require(
            caller == _msgSender(),
            "BurningZombiesMarket: caller is not the owner of the token"
        );
        _;
    }

    function createPrivateListing(
        uint256 tokenId,
        uint256 price,
        address buyer
    ) external whenNotPaused isTokenOwner(tokenId) {
        require(
            _masterContract.getApproved(tokenId) == address(this),
            "BurningZombiesMarket: market must be approved to transfer token"
        );
        _listings[tokenId] = Listing(_msgSender(), buyer, tokenId, price, true);
        emit ListingCreated(_msgSender(), buyer, tokenId, price);
    }

    function createListing(uint256 tokenId, uint256 price)
        external
        whenNotPaused
        isTokenOwner(tokenId)
    {
        require(
            _masterContract.getApproved(tokenId) == address(this),
            "BurningZombiesMarket: market must be approved to transfer token"
        );
        _listings[tokenId] = Listing(
            _msgSender(),
            address(0),
            tokenId,
            price,
            true
        );
        emit ListingCreated(_msgSender(), address(0), tokenId, price);
    }

    function getListing(uint256 tokenId)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        Listing memory listing = _listings[tokenId];
        return (
            listing.seller,
            listing.buyer,
            listing.tokenId,
            listing.price,
            listing.exists
        );
    }

    function cancelListing(uint256 tokenId)
        external
        whenNotPaused
        isTokenOwner(tokenId)
    {
        Listing memory trade = _listings[tokenId];
        require(
            trade.exists == true,
            "BurningZombiesMarket: token not for sale"
        );
        _listings[tokenId] = Listing(address(0), address(0), 0, 0, false);
        emit ListingCancelled(tokenId);
    }

    function buy(uint256 tokenId) external payable whenNotPaused nonReentrant {
        Listing memory trade = _listings[tokenId];
        require(
            trade.exists == true,
            "BurningZombiesMarket: token not for sale"
        );
        require(
            msg.value == trade.price,
            "BurningZombiesMarket: must send correct amount to buy"
        );
        require(
            _masterContract.ownerOf(tokenId) == trade.seller,
            "BurningZombiesMarket: seller must equal current token owner"
        );
        if (trade.buyer != address(0)) {
            require(
                trade.buyer == _msgSender(),
                "BurningZombiesMarket: listing is not available to the caller"
            );
        }

        address minter = _masterContract.minterOf(tokenId);

        Address.sendValue(
            payable(trade.seller),
            ((msg.value *
                (100 - (_devRoyalty + _minterRoyalty + _reflectionRoyalty))) /
                100)
        );

        Address.sendValue(payable(owner()), (msg.value * _devRoyalty) / 100);

        Address.sendValue(payable(minter), (msg.value * _minterRoyalty) / 100);

        _reflectDividend((msg.value * _reflectionRoyalty) / 100);

        _masterContract.transferFrom(trade.seller, _msgSender(), tokenId);
        _listings[tokenId] = Listing(address(0), address(0), 0, 0, false);

        emit Sale(trade.seller, _msgSender(), tokenId, msg.value);
    }

    function _reflectDividend(uint256 amount) private {
        reflectionBalance = reflectionBalance + amount;
        totalDividend =
            totalDividend +
            (amount / _masterContract.totalSupply());
    }

    function reflectToHolders() public payable {
        _reflectDividend(msg.value);
    }

    function currentRate() public view returns (uint256) {
        return reflectionBalance / _masterContract.totalSupply();
    }

    function claimReward(uint256 tokenId) public nonReentrant {
        require(
            _masterContract.ownerOf(tokenId) == _msgSender() ||
                _masterContract.getApproved(tokenId) == _msgSender(),
            "BurningZombiesMarket: Only owner or approved can claim rewards"
        );

        uint256 balance = getReflectionBalance(tokenId);
        Address.sendValue(payable(_masterContract.ownerOf(tokenId)), balance);
        _lastDividendAt[tokenId] = totalDividend;
    }

    function claimRewards() public nonReentrant {
        uint256 count = _masterContract.balanceOf(_msgSender());
        uint256 balance = 0;

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _masterContract.tokenOfOwnerByIndex(
                _msgSender(),
                i
            );
            balance += getReflectionBalance(tokenId);
            _lastDividendAt[tokenId] = totalDividend;
        }

        Address.sendValue(payable(_msgSender()), balance);
    }

    function getReflectionBalances() public view returns (uint256) {
        uint256 count = _masterContract.balanceOf(_msgSender());
        uint256 total = 0;
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _masterContract.tokenOfOwnerByIndex(
                _msgSender(),
                i
            );
            total += getReflectionBalance(tokenId);
        }
        return total;
    }

    function getReflectionBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return totalDividend - _lastDividendAt[tokenId];
    }

    function setDevRoyalty(uint256 royalty) external onlyOwner {
        _devRoyalty = royalty;
    }

    function setMinterRoyalty(uint256 royalty) external onlyOwner {
        _minterRoyalty = royalty;
    }

    function setReflectionRoyalty(uint256 royalty) external onlyOwner {
        _reflectionRoyalty = royalty;
    }

    function setMasterContractAddress(address contractAddress)
        external
        onlyOwner
    {
        _masterContract = IBurningZombiesERC721(contractAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
