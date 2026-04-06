// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BoraStaking} from "./BoraStaking.sol";

/**
 * @title BoraMarketplace
 * @notice Core marketplace for Bora Agent Market - handles listings, purchases, and commission
 * @dev Integrates with BoraStaking for validator capital enforcement
 */
contract BoraMarketplace is ReentrancyGuard, Ownable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant BASIS_POINTS = 10_000;
    uint256 private constant VALIDATOR_COMMISSION = 100;  // 1.0%
    uint256 private constant PLATFORM_FEE = 150;          // 1.5%
    uint256 private constant COMPLETION_DELAY = 72 hours;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable USDC;
    BoraStaking public immutable stakingContract;
    address public disputeContract;
    address public treasury;

    enum ListingStatus {
        ACTIVE,
        STAKED,
        PURCHASED,
        COMPLETED,
        DISPUTED,
        CANCELLED
    }

    struct Listing {
        uint256 id;
        address seller;
        uint256 price;
        string ipfsHash;           // Metadata: images, description, condition
        ListingStatus status;
        address validator;
        uint256 stakeId;
        address buyer;
        uint256 purchaseTimestamp;
        uint256 createdAt;
    }

    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) public sellerListings;
    mapping(address => uint256[]) public validatorListings;
    mapping(address => uint256[]) public buyerPurchases;
    
    uint256 public listingIdCounter;
    bool public paused;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        uint256 price,
        string ipfsHash
    );

    event ListingStaked(
        uint256 indexed listingId,
        address indexed validator,
        uint256 stakeId
    );

    event ListingPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 price
    );

    event ListingCompleted(
        uint256 indexed listingId,
        address seller,
        address validator,
        address buyer,
        uint256 sellerPayout,
        uint256 validatorCommission
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed seller
    );

    event DisputeInitiated(
        uint256 indexed listingId,
        address indexed buyer,
        string evidenceHash
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Paused();
    error Unauthorized();
    error InvalidPrice();
    error InvalidStatus();
    error ListingNotFound();
    error AlreadyStaked();
    error NotStaked();
    error InsufficientPayment();
    error TransferFailed();
    error TooEarlyToComplete();

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _usdc,
        address _stakingContract,
        address _treasury
    ) Ownable(msg.sender) {
        USDC = IERC20(_usdc);
        stakingContract = BoraStaking(_stakingContract);
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyDispute() {
        if (msg.sender != disputeContract) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         LISTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a new listing
     * @param price Item price in USDC (6 decimals)
     * @param ipfsHash IPFS hash containing item metadata
     * @return listingId Unique identifier for this listing
     */
    function createListing(uint256 price, string calldata ipfsHash) 
        external 
        whenNotPaused 
        returns (uint256 listingId)
    {
        if (price == 0) revert InvalidPrice();
        if (bytes(ipfsHash).length == 0) revert InvalidPrice();

        listingId = ++listingIdCounter;
        
        listings[listingId] = Listing({
            id: listingId,
            seller: msg.sender,
            price: price,
            ipfsHash: ipfsHash,
            status: ListingStatus.ACTIVE,
            validator: address(0),
            stakeId: 0,
            buyer: address(0),
            purchaseTimestamp: 0,
            createdAt: block.timestamp
        });

        sellerListings[msg.sender].push(listingId);

        emit ListingCreated(listingId, msg.sender, price, ipfsHash);
    }

    /**
     * @notice Validator stakes on a listing to verify authenticity
     * @param listingId The listing to validate
     */
    function stakeListing(uint256 listingId) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        Listing storage listing = listings[listingId];
        if (listing.price == 0) revert ListingNotFound();
        if (listing.status != ListingStatus.ACTIVE) revert InvalidStatus();

        // Lock validator stake via staking contract
        uint256 stakeId = stakingContract.lockStake(msg.sender, listingId, listing.price);

        // Update listing
        listing.status = ListingStatus.STAKED;
        listing.validator = msg.sender;
        listing.stakeId = stakeId;

        validatorListings[msg.sender].push(listingId);

        emit ListingStaked(listingId, msg.sender, stakeId);
    }

    /**
     * @notice Purchase a staked listing
     * @param listingId The listing to purchase
     */
    function purchaseListing(uint256 listingId) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        Listing storage listing = listings[listingId];
        if (listing.price == 0) revert ListingNotFound();
        if (listing.status != ListingStatus.STAKED) revert NotStaked();

        // Transfer USDC from buyer to contract (held in escrow)
        bool success = USDC.transferFrom(msg.sender, address(this), listing.price);
        if (!success) revert TransferFailed();

        // Update listing
        listing.status = ListingStatus.PURCHASED;
        listing.buyer = msg.sender;
        listing.purchaseTimestamp = block.timestamp;

        buyerPurchases[msg.sender].push(listingId);

        emit ListingPurchased(listingId, msg.sender, listing.price);
    }

    /**
     * @notice Complete sale after 72-hour window (no disputes)
     * @param listingId The listing to complete
     */
    function completeSale(uint256 listingId) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        Listing storage listing = listings[listingId];
        if (listing.price == 0) revert ListingNotFound();
        if (listing.status != ListingStatus.PURCHASED) revert InvalidStatus();
        
        // Enforce 72-hour completion delay
        if (block.timestamp < listing.purchaseTimestamp + COMPLETION_DELAY) {
            revert TooEarlyToComplete();
        }

        // Calculate payouts
        uint256 validatorCommission = (listing.price * VALIDATOR_COMMISSION) / BASIS_POINTS;
        uint256 platformFee = (listing.price * PLATFORM_FEE) / BASIS_POINTS;
        uint256 sellerPayout = listing.price - validatorCommission - platformFee;

        // Update status
        listing.status = ListingStatus.COMPLETED;

        // Release validator stake
        stakingContract.releaseStake(listing.stakeId);

        // Distribute funds
        bool success;
        success = USDC.transfer(listing.seller, sellerPayout);
        if (!success) revert TransferFailed();
        
        success = USDC.transfer(listing.validator, validatorCommission);
        if (!success) revert TransferFailed();
        
        success = USDC.transfer(treasury, platformFee);
        if (!success) revert TransferFailed();

        emit ListingCompleted(
            listingId,
            listing.seller,
            listing.validator,
            listing.buyer,
            sellerPayout,
            validatorCommission
        );
    }

    /**
     * @notice Cancel an active listing (seller only, before staking)
     * @param listingId The listing to cancel
     */
    function cancelListing(uint256 listingId) external whenNotPaused {
        Listing storage listing = listings[listingId];
        if (listing.seller != msg.sender) revert Unauthorized();
        if (listing.status != ListingStatus.ACTIVE) revert InvalidStatus();

        listing.status = ListingStatus.CANCELLED;

        emit ListingCancelled(listingId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        DISPUTE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initiate a dispute (buyer claims item is fake/not as described)
     * @param listingId The listing being disputed
     * @param evidenceHash IPFS hash of buyer's evidence (photos, etc.)
     */
    function initiateDispute(uint256 listingId, string calldata evidenceHash) 
        external 
        whenNotPaused 
    {
        Listing storage listing = listings[listingId];
        if (listing.buyer != msg.sender) revert Unauthorized();
        if (listing.status != ListingStatus.PURCHASED) revert InvalidStatus();

        listing.status = ListingStatus.DISPUTED;

        emit DisputeInitiated(listingId, msg.sender, evidenceHash);
    }

    /**
     * @notice Resolve dispute in buyer's favor (called by dispute contract)
     * @param listingId The disputed listing
     */
    function resolveDisputeBuyerWins(uint256 listingId) 
        external 
        onlyDispute 
        nonReentrant 
    {
        Listing storage listing = listings[listingId];
        if (listing.status != ListingStatus.DISPUTED) revert InvalidStatus();

        // Slash validator stake (goes to buyer)
        stakingContract.slashStake(listing.stakeId, listing.buyer);

        // Refund buyer's payment
        bool success = USDC.transfer(listing.buyer, listing.price);
        if (!success) revert TransferFailed();

        listing.status = ListingStatus.COMPLETED; // Mark as resolved
    }

    /**
     * @notice Resolve dispute in validator's favor (called by dispute contract)
     * @param listingId The disputed listing
     */
    function resolveDisputeValidatorWins(uint256 listingId) 
        external 
        onlyDispute 
        nonReentrant 
    {
        Listing storage listing = listings[listingId];
        if (listing.status != ListingStatus.DISPUTED) revert InvalidStatus();

        // Treat as normal completion
        listing.status = ListingStatus.PURCHASED;
        
        // Can now be completed normally via completeSale
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    function getSellerListings(address seller) external view returns (uint256[] memory) {
        return sellerListings[seller];
    }

    function getValidatorListings(address validator) external view returns (uint256[] memory) {
        return validatorListings[validator];
    }

    function getBuyerPurchases(address buyer) external view returns (uint256[] memory) {
        return buyerPurchases[buyer];
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setDisputeContract(address _dispute) external onlyOwner {
        disputeContract = _dispute;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function emergencyPause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }
}
