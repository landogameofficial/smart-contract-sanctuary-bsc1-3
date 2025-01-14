// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/ICollectionFeesCalculator.sol";
import "./interfaces/ICollectionWhitelistChecker.sol";

contract Marketplace is Pausable, Ownable, ReentrancyGuard, ERC721Holder {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant ONE_HUNDRED_PERCENT = 10000; // 100%
    uint256 public constant MAX_CREATOR_FEE_PERCENT = 2000; // 20%
    uint256 public constant MAX_TRADING_FEE_PERCENT = 2000; // 20%

    uint256 public totalAsks;
    uint256 public totalBids;

    enum CollectionStatus {
        Pending,
        Open,
        Close
    }
    struct Collection {
        address collection;
        CollectionStatus status; // status of the collection
        address creator;
        uint256 creatorFeePercent;
        address whitelistChecker; // whitelist checker (if not set --> 0x00)
    }

    struct Ask {
        address collection;
        uint256 tokenId;
        address seller; // address of the seller
        uint256 price; // price of the token
    }

    struct Bid {
        address bidder;
        uint256 price;
    }

    mapping(address => bool) public admins;
    address public immutable tokenPayment;

    address public treasury;
    uint256 public tradingFeePercent;
    uint256 public pendingRevenueTradingFee;

    // collection => total CreatorFee
    mapping(address => uint256) public pendingRevenueCreatorFeeOfCollection;

    EnumerableSet.AddressSet private collectionAddressSet;
    // collection => Collection Info
    mapping(address => Collection) public collections;

    // askId => Ask
    EnumerableSet.UintSet private askIds;
    // askId => Ask
    mapping(uint256 => Ask) public asks;

    // collection => listAskId
    mapping(address => EnumerableSet.UintSet) private askIdsOfCollection;
    // seller => listAskId
    mapping(address => EnumerableSet.UintSet) private askIdsOfSeller;

    // askId => bidId
    mapping(uint256 => uint256) public bestBidIdOfAskId;

    // bidId => Bid
    mapping(uint256 => Bid) public bids;

    //  change Treasury address
    event NewTreasuryAddresses(address treasury);

    //  change TradingFeePercent address
    event NewTradingFeePercent(
        uint256 oldTradingFeePercent,
        uint256 newTradingFeePercent
    );

    // update admin market
    event UpdateAdmins(address[] admins, bool isAdd);

    // New collection is added
    event CollectionNew(
        address indexed collection,
        address indexed creator,
        uint256 creatorFeePercent,
        address indexed whitelistChecker
    );

    // Existing collection is updated
    event CollectionUpdate(
        address indexed collection,
        address indexed creator,
        uint256 creatorFeePercent,
        address indexed whitelistChecker
    );

    event CollectionChangeStatus(
        address indexed collection,
        CollectionStatus oldStatus,
        CollectionStatus newStatus
    );

    event CollectionChangeCreator(
        address indexed collection,
        address oldCreator,
        address newCreator
    );

    event CollectionRemove(address indexed collection);

    event RevenueTradingFeeClaim(
        address indexed claimer,
        address indexed treasury,
        uint256 amount
    );

    event RevenueCreatorFeeClaim(
        address indexed claimer,
        address indexed creator,
        address indexed collection,
        uint256 amount
    );

    event AskListing(
        uint256 indexed askId,
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    event AskUpdatePrice(
        uint256 indexed askId,
        uint256 oldPrice,
        uint256 newPrice
    );

    event AskSale(
        uint256 indexed askId,
        address indexed seller,
        address indexed buyer,
        uint256 grossPrice,
        uint256 netPrice
    );

    event AskCancelListing(uint256 indexed askId);

    event BidCreated(
        uint256 indexed askId,
        uint256 indexed bidId,
        address indexed bidder
    );

    event BidCanceled(uint256 indexed askId, uint256 indexed bidId);

    event BidAccepted(
        uint256 indexed askId,
        uint256 indexed bidId,
        address seller,
        address bidder,
        uint256 price,
        uint256 priceAccepted
    );

    // Modifier checking Admin role
    modifier onlyAdmin() {
        require(
            msg.sender != ZERO_ADDRESS && admins[msg.sender],
            "Auth: Account not role admin"
        );
        _;
    }
    modifier verifyCollection(address collection) {
        // Verify collection is accepted
        require(
            collectionAddressSet.contains(collection),
            "Operations: Collection not listed"
        );
        // require(
        //     collections[collection].status == CollectionStatus.Open,
        //     "Collection: Not for listing"
        // );
        _;
    }

    modifier verifyTradingFeePercent(uint256 newTradingFeePercent) {
        // Verify collection is accepted
        require(
            newTradingFeePercent >= 0 &&
                newTradingFeePercent <= MAX_TRADING_FEE_PERCENT,
            "Operations: Trading fee percent not within range"
        );
        _;
    }

    modifier verifyCreatorFeePercent(uint256 newCreatorFeePercent) {
        // Verify collection is accepted
        require(
            newCreatorFeePercent >= 0 &&
                newCreatorFeePercent <= MAX_CREATOR_FEE_PERCENT,
            "Operations: Creator fee percent not within range"
        );
        _;
    }

    modifier verifyPrice(uint256 price) {
        // Verify price
        require(price >= 0, "Order: Price not within range");
        _;
    }

    modifier verifyAsk(uint256 askId) {
        require(askIds.contains(askId), "Order: AskId not existed");
        require(
            collections[asks[askId].collection].status == CollectionStatus.Open,
            "Collection: Not for listing"
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _treasury: address of the treasury
     * @param _tokenPayment: tokenPayment address
     */
    constructor(
        address _tokenPayment,
        address _treasury,
        uint256 _tradingFeePercent
    ) verifyTradingFeePercent(_tradingFeePercent) {
        require(
            _treasury != address(0),
            "Operations: Treasury address cannot be zero"
        );
        require(
            _tokenPayment != address(0),
            "Operations: tokenPayment address cannot be zero"
        );
        treasury = _treasury;
        tokenPayment = _tokenPayment;
        admins[msg.sender] = true;
        tradingFeePercent = _tradingFeePercent;
        totalAsks = 0;
        totalBids = 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function calculatePriceAndFeesForCollection(
        address _collection,
        uint256 _grossPrice
    )
        public
        view
        returns (
            uint256 netPrice,
            uint256 tradingFee,
            uint256 creatorFee
        )
    {
        tradingFee = (_grossPrice * tradingFeePercent) / ONE_HUNDRED_PERCENT;
        creatorFee =
            (_grossPrice * collections[_collection].creatorFeePercent) /
            ONE_HUNDRED_PERCENT;
        netPrice = _grossPrice - tradingFee - creatorFee;
        return (netPrice, tradingFee, creatorFee);
    }

    function updateAdmins(address[] memory _admins, bool _isAdd)
        external
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = _isAdd;
        }
        emit UpdateAdmins(_admins, _isAdd);
    }

    /**
     * @notice Set admin address
     * @dev Only callable by owner
     * @param _treasury: address of the treasury
     */
    function setTreasuryAddresses(address _treasury) external onlyOwner {
        require(
            _treasury != ZERO_ADDRESS,
            "Operations: Treasury address cannot be zero"
        );
        treasury = _treasury;

        emit NewTreasuryAddresses(_treasury);
    }

    /**
     * @notice Set admin address
     * @dev Only callable by owner
     * @param _tradingFeePercent: new _tradingFeePercent
     */
    function setTradingFeePercent(uint256 _tradingFeePercent)
        external
        onlyOwner
        verifyTradingFeePercent(_tradingFeePercent)
    {
        emit NewTradingFeePercent(tradingFeePercent, _tradingFeePercent);
        tradingFeePercent = _tradingFeePercent;
    }

    /**
     * @notice Add a new collection
     * @param _collection: collection address
     * @param _creator: address fee creator
     * @param _creatorFeePercent: creator fee percent
     * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
   
     * @dev Callable by owner
     */
    function addCollection(
        address _collection,
        address _creator,
        uint256 _creatorFeePercent,
        address _whitelistChecker
    )
        external
        onlyAdmin
        whenNotPaused
        verifyCreatorFeePercent(_creatorFeePercent)
    {
        require(
            !collectionAddressSet.contains(_collection),
            "Operations: Collection already listed"
        );
        require(
            IERC721(_collection).supportsInterface(IID_IERC721),
            "Operations: Not ERC721"
        );

        require(_creator != ZERO_ADDRESS, "Operations: Creator zero address");

        collectionAddressSet.add(_collection);
        collections[_collection] = Collection({
            collection: _collection,
            status: CollectionStatus.Open,
            creator: _creator,
            creatorFeePercent: _creatorFeePercent,
            whitelistChecker: _whitelistChecker
        });

        emit CollectionNew(
            _collection,
            _creator,
            _creatorFeePercent,
            _whitelistChecker
        );
    }

    /**
     * @notice Modify collection characteristics
     * @param _collection: collection address
     * @param _creator: address fee creator
     * @param _creatorFeePercent: creator fee percent
     * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
     * @dev Callable by admin
     */
    function modifyCollection(
        address _collection,
        address _creator,
        uint256 _creatorFeePercent,
        address _whitelistChecker
    )
        external
        onlyAdmin
        whenNotPaused
        verifyCollection(_collection)
        verifyCreatorFeePercent(_creatorFeePercent)
    {
        collections[_collection] = Collection({
            collection: _collection,
            status: collections[_collection].status,
            creator: _creator,
            creatorFeePercent: _creatorFeePercent,
            whitelistChecker: _whitelistChecker
        });
        emit CollectionUpdate(
            _collection,
            _creator,
            _creatorFeePercent,
            _whitelistChecker
        );
    }

    /**
     * @notice Modify collection characteristics
     * @param _collection: collection address
     * @param _status: collectionStatus
     * @dev Callable by admin
     */
    function changeCollectionStatus(
        address _collection,
        CollectionStatus _status
    ) external onlyAdmin whenNotPaused verifyCollection(_collection) {
        // CollectionStatus oldStatus = collections[_collection].status;
        emit CollectionChangeStatus(
            _collection,
            collections[_collection].status,
            _status
        );
        collections[_collection].status = _status;
    }

    /**
     * @notice changeCreatorCollection
     * @param _collection: collection address
     * @param _newCreator: newCreator
     * @dev Callable by admin
     */
    function changeCreatorCollection(address _collection, address _newCreator)
        external
        onlyAdmin
        whenNotPaused
        verifyCollection(_collection)
    {
        require(
            _newCreator != ZERO_ADDRESS,
            "Operations: New creator zero address"
        );
        emit CollectionChangeCreator(
            _collection,
            collections[_collection].creator,
            _newCreator
        );
        collections[_collection].creator = _newCreator;
    }

    /**
     * @notice remove collection to market
     * @param _collection: collection address
     * @dev Callable by admin
     */
    function removeCollection(address _collection)
        external
        onlyAdmin
        whenNotPaused
        verifyCollection(_collection)
    {
        delete collections[_collection];
        collectionAddressSet.remove(_collection);
        emit CollectionRemove(_collection);
    }

    /**
     * @notice Checks if a token can be listed
     * @param _collection: address of the collection
     * @param _tokenId: tokenId
     */
    function canTokenBeListed(address _collection, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        address whitelistCheckerAddress = collections[_collection]
            .whitelistChecker;
        return
            (whitelistCheckerAddress == ZERO_ADDRESS) ||
            ICollectionWhitelistChecker(whitelistCheckerAddress).canList(
                _tokenId
            );
    }

    /**
     * @notice Checks if an array of tokenIds can be listed
     * @param _collection: address of the collection
     * @param _tokenIds: array of tokenIds
     * @dev if collection is not for trading, it returns array of bool with false
     */
    function canTokensBeListed(
        address _collection,
        uint256[] calldata _tokenIds
    ) external view returns (bool[] memory listingStatuses) {
        listingStatuses = new bool[](_tokenIds.length);

        if (collections[_collection].status != CollectionStatus.Open) {
            return listingStatuses;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            listingStatuses[i] = canTokenBeListed(_collection, _tokenIds[i]);
        }

        return listingStatuses;
    }

    /**
     * @notice askListing
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _price: price for listing (in tokenPayment)
     */
    function askListing(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    )
        external
        whenNotPaused
        nonReentrant
        verifyPrice(_price)
        returns (uint256)
    {
        require(
            canTokenBeListed(_collection, _tokenId),
            "Order: tokenId not eligible"
        );
        // Transfer NFT to this contract
        IERC721(_collection).safeTransferFrom(
            address(msg.sender),
            address(this),
            _tokenId
        );
        uint256 askId = ++totalAsks;
        // add listAskId
        askIds.add(askId);
        // add Ask to askList
        asks[askId] = Ask({
            collection: _collection,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price
        });
        askIdsOfCollection[_collection].add(askId);
        askIdsOfSeller[msg.sender].add(askId);
        emit AskListing(askId, msg.sender, _collection, _tokenId, _price);
        return askId;
    }

    /**
     * @notice askUpdatePrice
     * @param _askId: askId
     * @param _newPrice: newPrice for listing (in tokenPayment)
     */
    function askUpdatePrice(uint256 _askId, uint256 _newPrice)
        external
        whenNotPaused
        nonReentrant
        verifyPrice(_newPrice)
        verifyAsk(_askId)
        returns (uint256)
    {
        require(
            askIdsOfSeller[msg.sender].contains(_askId),
            "Order: AskId do not own your ownership"
        );
        emit AskUpdatePrice(_askId, asks[_askId].price, _newPrice);
        asks[_askId].price = _newPrice;
        return _askId;
    }

    /**
     * @notice askCancelListing
     * @param _askId: askId
     */
    function askCancelListing(uint256 _askId)
        external
        whenNotPaused
        nonReentrant
        verifyAsk(_askId)
        returns (uint256)
    {
        require(
            askIdsOfSeller[msg.sender].contains(_askId),
            "Order: AskId do not own your ownership"
        );
        uint256 bidId = bestBidIdOfAskId[_askId];
        if (bidId > 0) {
            _bidCancel(_askId, bidId);
        }

        // Transfer NFT to seller
        IERC721(asks[_askId].collection).safeTransferFrom(
            address(this),
            address(msg.sender),
            asks[_askId].tokenId
        );

        askIdsOfSeller[msg.sender].remove(_askId);
        askIdsOfCollection[asks[_askId].collection].remove(_askId);
        askIds.remove(_askId);
        delete asks[_askId];

        emit AskCancelListing(_askId);
        return _askId;
    }

    /**
     * @notice askSale
     * @param _askId: askId
     * @param _price: price buy (in tokenPayment)
     */
    function askSale(uint256 _askId, uint256 _price)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        IERC20(tokenPayment).safeTransferFrom(
            address(msg.sender),
            address(this),
            _price
        );
        return _askSale(_askId, _price);
    }

    /**
     * @notice askSale
     * @param _askIds: listAskId
     * @param _prices: list price buy (in tokenPayment)
     */
    function askSales(uint256[] calldata _askIds, uint256[] calldata _prices)
        external
        whenNotPaused
        nonReentrant
        returns (uint256[] memory outputAskIds)
    {
        require(
            _askIds.length == _prices.length && _askIds.length > 0,
            "Invalid input "
        );

        uint256 totalPrice = 0;
        outputAskIds = new uint256[](_prices.length);
        for (uint256 index = 0; index < _prices.length; index++) {
            totalPrice += _prices[index];
        }
        IERC20(tokenPayment).safeTransferFrom(
            address(msg.sender),
            address(this),
            totalPrice
        );
        for (uint256 index = 0; index < _prices.length; index++) {
            outputAskIds[index] = _askSale(_askIds[index], _prices[index]);
        }
        return outputAskIds;
    }

    function _askSale(uint256 _askId, uint256 _price)
        private
        verifyPrice(_price)
        verifyAsk(_askId)
        returns (uint256)
    {
        Ask memory askOrder = asks[_askId];
        // Front-running protection
        require(_price == askOrder.price, "Buy: Incorrect price");
        require(msg.sender != askOrder.seller, "Buy: Buyer cannot be seller");
        (
            uint256 netPrice,
            uint256 tradingFee,
            uint256 creatorFee
        ) = calculatePriceAndFeesForCollection(askOrder.collection, _price);

        askIdsOfSeller[askOrder.seller].remove(_askId);
        askIdsOfCollection[askOrder.collection].remove(_askId);
        askIds.remove(_askId);
        delete asks[_askId];

        IERC20(tokenPayment).safeTransfer(askOrder.seller, netPrice);

        if (tradingFee > 0) {
            pendingRevenueTradingFee += tradingFee;
        }
        if (creatorFee > 0) {
            pendingRevenueCreatorFeeOfCollection[
                askOrder.collection
            ] += creatorFee;
        }
        // Transfer NFT to buyer
        IERC721(askOrder.collection).safeTransferFrom(
            address(this),
            address(msg.sender),
            askOrder.tokenId
        );

        uint256 bidId = bestBidIdOfAskId[_askId];

        if (bidId > 0) {
            _bidCancel(_askId, bidId);
        }

        emit AskSale(
            _askId,
            askOrder.seller,
            address(msg.sender),
            _price,
            netPrice
        );
        return _askId;
    }

    /**
     * @notice bid
     * @param _askId: askId
     * @param _price: newPrice for listing (in tokenPayment)
     */
    function bid(uint256 _askId, uint256 _price)
        external
        whenNotPaused
        nonReentrant
        verifyPrice(_price)
        verifyAsk(_askId)
        returns (uint256)
    {
        uint256 oldBidId = bestBidIdOfAskId[_askId];
        if (oldBidId > 0) {
            Bid memory oldBid = bids[oldBidId];
            require(_price > oldBid.price, "Bid: New bid invalid price");
            if (oldBid.bidder == msg.sender) {
                IERC20(tokenPayment).safeTransferFrom(
                    address(msg.sender),
                    address(this),
                    _price - oldBid.price
                );
            } else {
                IERC20(tokenPayment).safeTransfer(oldBid.bidder, oldBid.price);
                IERC20(tokenPayment).safeTransferFrom(
                    address(msg.sender),
                    address(this),
                    _price
                );
            }
            delete bids[oldBidId];
            emit BidCanceled(_askId, oldBidId);
            uint256 newBidId = ++totalBids;
            bestBidIdOfAskId[_askId] = newBidId;
            bids[newBidId] = Bid({bidder: msg.sender, price: _price});

            emit BidCreated(_askId, newBidId, msg.sender);
            return newBidId;
        }
        // Deposit amount bidding
        IERC20(tokenPayment).safeTransferFrom(
            address(msg.sender),
            address(this),
            _price
        );

        uint256 bidId = ++totalBids;
        bestBidIdOfAskId[_askId] = bidId;
        bids[bidId] = Bid({bidder: msg.sender, price: _price});
        emit BidCreated(_askId, bidId, msg.sender);
        return bidId;
    }

    /**
     * @notice bidCancel
     * @param _askId: askId
     * @param _bidId: bidId
     */
    function bidCancel(uint256 _askId, uint256 _bidId)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(
            msg.sender == bids[_bidId].bidder,
            "Bid: Account must be bidder"
        );
        return _bidCancel(_askId, _bidId);
    }

    function _bidCancel(uint256 _askId, uint256 _bidId)
        private
        returns (uint256)
    {
        IERC20(tokenPayment).safeTransfer(
            bids[_bidId].bidder,
            bids[_bidId].price
        );
        delete bestBidIdOfAskId[_askId];
        delete bids[_bidId];
        emit BidCanceled(_askId, _bidId);
        return _bidId;
    }

    /**
     * @notice acceptBid
     * @param _askId: askId
     * @param _price: price accept
     */
    function acceptBid(uint256 _askId, uint256 _price)
        external
        whenNotPaused
        nonReentrant
        verifyPrice(_price)
        verifyAsk(_askId)
        returns (uint256)
    {
        uint256 bidId = bestBidIdOfAskId[_askId];

        require(bidId > 0, "Bid: bidId invalid");
        Bid memory bestBid = bids[bidId];
        require(bestBid.price >= _price, "Under price accepted");
        Ask memory askOrder = asks[_askId];
        // Front-running protection
        require(msg.sender == askOrder.seller, "Buy: Your not owner ask");
        (
            uint256 netPrice,
            uint256 tradingFee,
            uint256 creatorFee
        ) = calculatePriceAndFeesForCollection(
                askOrder.collection,
                bestBid.price
            );

        IERC20(tokenPayment).safeTransfer(askOrder.seller, netPrice);

        if (tradingFee > 0) {
            pendingRevenueTradingFee += tradingFee;
        }
        if (creatorFee > 0) {
            pendingRevenueCreatorFeeOfCollection[
                askOrder.collection
            ] += creatorFee;
        }
        // Transfer NFT to bidder
        IERC721(askOrder.collection).safeTransferFrom(
            address(this),
            bestBid.bidder,
            askOrder.tokenId
        );

        askIdsOfSeller[askOrder.seller].remove(_askId);
        askIdsOfCollection[askOrder.collection].remove(_askId);
        askIds.remove(_askId);
        delete asks[_askId];

        delete bestBidIdOfAskId[_askId];
        delete bids[bidId];

        emit BidAccepted(
            _askId,
            bidId,
            askOrder.seller,
            bestBid.bidder,
            bestBid.price,
            _price
        );

        return bidId;
    }

    /**
     * @notice Claim pending revenue (treasury or creators)
     */
    function claimPendingTradingFee() external nonReentrant {
        require(pendingRevenueTradingFee > 0, "Claim: Nothing to claim");
        IERC20(tokenPayment).safeTransfer(treasury, pendingRevenueTradingFee);

        emit RevenueTradingFeeClaim(
            msg.sender,
            treasury,
            pendingRevenueTradingFee
        );
        pendingRevenueTradingFee = 0;
    }

    /**
     * @notice Claim pending revenue (treasury or creators)
     * @param _collection: collection address
     */
    function claimPendingCreatorFee(address _collection) external nonReentrant {
        uint256 amount = pendingRevenueCreatorFeeOfCollection[_collection];
        require(amount > 0, "Claim: Nothing to claim");
        IERC20(tokenPayment).safeTransfer(
            collections[_collection].creator,
            amount
        );
        emit RevenueCreatorFeeClaim(
            msg.sender,
            collections[_collection].creator,
            _collection,
            amount
        );
        pendingRevenueCreatorFeeOfCollection[_collection] = 0;
    }

    function viewAskIds(uint256 pageIndex, uint256 pageSize)
        external
        view
        returns (uint256[] memory data, uint256 total)
    {
        total = askIds.length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }

        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new uint256[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = askIds.at(i);
        }
        return (data, total);
    }

    function viewAsks(uint256 pageIndex, uint256 pageSize)
        external
        view
        returns (Ask[] memory data, uint256 total)
    {
        total = askIds.length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }

        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new Ask[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new Ask[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = asks[askIds.at(i)];
        }
        return (data, total);
    }

    function viewCollections(uint256 pageIndex, uint256 pageSize)
        external
        view
        returns (Collection[] memory data, uint256 total)
    {
        total = collectionAddressSet.length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }
        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new Collection[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new Collection[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = collections[collectionAddressSet.at(i)];
        }
        return (data, total);
    }

    function viewAskIdsByCollection(
        address collection,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (uint256[] memory data, uint256 total) {
        total = askIdsOfCollection[collection].length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }
        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new uint256[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = askIdsOfCollection[collection].at(i);
        }
        return (data, total);
    }

    function viewAsksByCollection(
        address collection,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (Ask[] memory data, uint256 total) {
        total = askIdsOfCollection[collection].length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }
        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new Ask[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new Ask[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = asks[askIdsOfCollection[collection].at(i)];
        }
        return (data, total);
    }

    function viewAskIdsBySeller(
        address seller,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (uint256[] memory data, uint256 total) {
        total = askIdsOfSeller[seller].length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }
        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new uint256[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = askIdsOfSeller[seller].at(i);
        }
        return (data, total);
    }

    function viewAsksBySeller(
        address seller,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (Ask[] memory data, uint256 total) {
        total = askIdsOfSeller[seller].length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }
        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new Ask[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new Ask[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = asks[askIdsOfSeller[seller].at(i)];
        }
        return (data, total);
    }

    function viewBidIdsBySeller(
        address seller,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (uint256[] memory data, uint256 total) {
        total = askIdsOfSeller[seller].length();
        if (pageIndex < 1) {
            pageIndex = 1;
        }
        uint256 startIndex = (pageIndex - 1) * pageSize;
        if (startIndex >= total) {
            return (new uint256[](0), total);
        }

        uint256 endIndex = pageIndex * pageSize > total
            ? total
            : pageIndex * pageSize;
        data = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = bestBidIdOfAskId[
                askIdsOfSeller[seller].at(i)
            ];
        }
        return (data, total);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollectionFeesCalculator {
    function creator() external view returns (address);

    function calculatePriceAndFees(address _buyer, uint256 _grossPrice)
        external
        view
        returns (
            uint256 netPrice,
            uint256 tradingFee,
            uint256 creatorFee
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollectionWhitelistChecker {
    function canList(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}