//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IBurningZombiesERC721 } from "./interfaces/IBurningZombiesERC721.sol";

/// @title BurningZombiesMarket
/// @author root36x9
contract BurningZombiesMarket is Ownable, Pausable, ReentrancyGuard {
    /// @dev Emitted when a token sold.
    /// @param seller The address of the seller.
    /// @param buyer The address of the buyer.
    /// @param tokenId Sold tokenId.
    /// @param price Sold price.
    event Sale(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @dev Emitted when a token listed.
    /// @param seller The address of the seller.
    /// @param buyer The address of the buyer.
    /// @param tokenId Sold tokenId.
    /// @param price Listing amount.
    event ListingCreated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @dev Emitted when listing cancelled.
    /// @param tokenId Token ID of the cancelled listing.
    event ListingCancelled(uint256 indexed tokenId);

    /// @dev Instance of the minting contract.
    IBurningZombiesERC721 private _masterContract;

    /// @dev Minter's royalty amount (%).
    uint256 private _minterRoyalty;

    /// @dev Community's royalty amount (%).
    uint256 private _reflectionRoyalty;

    /// @dev Dev's royalty amount (%).
    uint256 private _devRoyalty;

    /// @dev Liq royalty amount (%).
    uint256 private _liqRoyalty;

    /// @dev Liq address.
    address public liqAddress;

    /// @dev Sum of the reflection.
    uint256 public reflectionBalance;

    /// @dev Amount of reflection per token owner.
    uint256 public totalDividend;

    /// @dev Mapping from token ID to last claimed amount.
    mapping(uint256 => uint256) private _lastDividendAt;

    /// @param seller Seller.
    /// @param buyer Buyer.
    /// @param tokenId Token ID.
    /// @param price Price.
    /// @param exists Is the token on sale?
    struct Listing {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 price;
        bool exists;
    }

    /// @dev Mapping from token ID to Listing.
    mapping(uint256 => Listing) private _listings;

    /// @dev Initializes the contract.
    /// @param masterContractAddress Minting contract address.
    /// @param devRoyalty Dev's royalty amount (%).
    /// @param minterRoyalty Minter's royalty amount (%).
    /// @param reflectionRoyalty Community's royalty amount (%).
    /// @param liqRoyalty Community's royalty amount (%).
    constructor(
        address masterContractAddress,
        uint256 devRoyalty,
        uint256 minterRoyalty,
        uint256 reflectionRoyalty,
        address liqAddress_,
        uint256 liqRoyalty
    ) {
        _masterContract = IBurningZombiesERC721(masterContractAddress);
        _minterRoyalty = minterRoyalty;
        _devRoyalty = devRoyalty;
        _reflectionRoyalty = reflectionRoyalty;
        liqAddress = liqAddress_;
        _liqRoyalty = liqRoyalty;
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

    /// @dev Creates private listing to an account.
    /// @param tokenId Token ID,
    /// @param price The price of the token.
    /// @param buyer The address of the buyer, only buyer can buy the token.
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

    /// @dev Creates public listing.
    /// @param tokenId Token ID,
    /// @param price The price of the token.
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

    /// @dev Getter for the listing.
    /// @param tokenId Token ID.
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

    /// @dev Cancel listing.
    /// @param tokenId Token ID.
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

    /// @dev Buy the token.
    /// @param tokenId Token ID.
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
                (100 -
                    (_devRoyalty +
                        _minterRoyalty +
                        _reflectionRoyalty +
                        _liqRoyalty))) / 100)
        );

        Address.sendValue(payable(owner()), (msg.value * _devRoyalty) / 100);

        Address.sendValue(payable(minter), (msg.value * _minterRoyalty) / 100);

        Address.sendValue(payable(liqAddress), (msg.value * _liqRoyalty) / 100);

        _reflectDividend((msg.value * _reflectionRoyalty) / 100);

        _masterContract.transferFrom(trade.seller, _msgSender(), tokenId);
        _listings[tokenId] = Listing(address(0), address(0), 0, 0, false);

        emit Sale(trade.seller, _msgSender(), tokenId, msg.value);
    }

    /// @dev Distributes the given amount to the community.
    /// @param amount The amount to the distribute.
    function _reflectDividend(uint256 amount) private {
        reflectionBalance = reflectionBalance + amount;
        totalDividend =
            totalDividend +
            (amount / _masterContract.totalSupply());
    }

    /// @dev Reflect the recevied amount to the holders.
    function reflectToHolders() public payable {
        _reflectDividend(msg.value);
    }

    /// @dev Getter for the current reflection rate.
    function currentRate() public view returns (uint256) {
        return reflectionBalance / _masterContract.totalSupply();
    }

    /// @dev Claims the fiven token's reflected amounts.
    /// @param tokenId Token ID.
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

    /// @dev Claims all reflected amounts from sender's tokens.
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

    /// @dev Getter for the reflection balances.
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

    /// @dev Getter for the reflection balance the given token.
    /// @param tokenId The token ID.
    function getReflectionBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return totalDividend - _lastDividendAt[tokenId];
    }

    /// @dev Setter for the dev's royalty amount.
    /// @param royalty The amount of the royalty.
    function setDevRoyalty(uint256 royalty) external onlyOwner {
        _devRoyalty = royalty;
    }

    /// @dev Setter for the liq royalty amount.
    /// @param royalty The amount of the royalty.
    function setLiqRoyalty(uint256 royalty) external onlyOwner {
        _liqRoyalty = royalty;
    }

    /// @dev Setter for the liq address.
    /// @param account Liq address.
    function setLiqRoyalty(address account) external onlyOwner {
        liqAddress = account;
    }

    /// @dev Setter for the minter's royalty amount.
    /// @param royalty The amount of the royalty.
    function setMinterRoyalty(uint256 royalty) external onlyOwner {
        _minterRoyalty = royalty;
    }

    /// @dev Setter for the community's royalty amount.
    /// @param royalty The amount of the royalty.
    function setReflectionRoyalty(uint256 royalty) external onlyOwner {
        _reflectionRoyalty = royalty;
    }

    /// @dev Setter for the minting contract.
    /// @param contractAddress The contract address.
    function setMasterContractAddress(address contractAddress)
        external
        onlyOwner
    {
        _masterContract = IBurningZombiesERC721(contractAddress);
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
