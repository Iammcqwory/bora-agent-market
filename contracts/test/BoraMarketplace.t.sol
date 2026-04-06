// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {BoraMarketplace} from "../src/BoraMarketplace.sol";
import {BoraStaking} from "../src/BoraStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract BoraMarketplaceTest is Test {
    BoraMarketplace public marketplace;
    BoraStaking public staking;
    ERC20Mock public usdc;
    
    address public owner = address(1);
    address public treasury = address(2);
    address public insurancePool = address(3);
    address public seller = address(4);
    address public validator = address(5);
    address public buyer = address(6);

    uint256 constant INITIAL_BALANCE = 100_000e6; // $100k USDC

    function setUp() public {
        // Deploy mock USDC
        usdc = new ERC20Mock();
        
        // Deploy staking contract
        vm.prank(owner);
        staking = new BoraStaking(address(usdc), insurancePool);
        
        // Deploy marketplace
        vm.prank(owner);
        marketplace = new BoraMarketplace(
            address(usdc),
            address(staking),
            treasury
        );

        // Connect contracts
        vm.startPrank(owner);
        staking.setMarketplaceContract(address(marketplace));
        vm.stopPrank();

        // Fund accounts
        usdc.mint(seller, INITIAL_BALANCE);
        usdc.mint(validator, INITIAL_BALANCE);
        usdc.mint(buyer, INITIAL_BALANCE);

        // Approvals
        vm.prank(seller);
        usdc.approve(address(marketplace), type(uint256).max);
        
        vm.prank(validator);
        usdc.approve(address(staking), type(uint256).max);
        
        vm.prank(buyer);
        usdc.approve(address(marketplace), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                         LISTING CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CreateListing_Success() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");

        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        
        assertEq(listingId, 1);
        assertEq(listing.seller, seller);
        assertEq(listing.price, 300e6);
        assertEq(listing.ipfsHash, "QmTest123");
        assertTrue(uint8(listing.status) == 0); // ACTIVE
    }

    function test_CreateListing_ZeroPrice() public {
        vm.prank(seller);
        vm.expectRevert(BoraMarketplace.InvalidPrice.selector);
        marketplace.createListing(0, "QmTest123");
    }

    function test_CreateListing_EmptyIPFS() public {
        vm.prank(seller);
        vm.expectRevert(BoraMarketplace.InvalidPrice.selector);
        marketplace.createListing(300e6, "");
    }

    /*//////////////////////////////////////////////////////////////
                           STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_StakeListing_Success() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");

        uint256 validatorBalanceBefore = usdc.balanceOf(validator);

        // Validator stakes
        vm.prank(validator);
        marketplace.stakeListing(listingId);

        // Verify listing updated
        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertTrue(uint8(listing.status) == 1); // STAKED
        assertEq(listing.validator, validator);
        assertTrue(listing.stakeId > 0);

        // Verify stake was locked
        uint256 requiredStake = staking.getRequiredStake(300e6);
        uint256 premium = (requiredStake * 200) / 10_000;
        assertEq(
            usdc.balanceOf(validator),
            validatorBalanceBefore - requiredStake - premium
        );
    }

    function test_StakeListing_AlreadyStaked() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");

        vm.prank(validator);
        marketplace.stakeListing(listingId);

        // Try to stake again
        vm.prank(validator);
        vm.expectRevert(BoraMarketplace.InvalidStatus.selector);
        marketplace.stakeListing(listingId);
    }

    /*//////////////////////////////////////////////////////////////
                          PURCHASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PurchaseListing_Success() public {
        // Setup: Create and stake listing
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");
        
        vm.prank(validator);
        marketplace.stakeListing(listingId);

        uint256 buyerBalanceBefore = usdc.balanceOf(buyer);

        // Purchase
        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        // Verify listing updated
        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertTrue(uint8(listing.status) == 2); // PURCHASED
        assertEq(listing.buyer, buyer);
        assertTrue(listing.purchaseTimestamp > 0);

        // Verify payment held in escrow
        assertEq(usdc.balanceOf(buyer), buyerBalanceBefore - 300e6);
        assertEq(usdc.balanceOf(address(marketplace)), 300e6);
    }

    function test_PurchaseListing_NotStaked() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");

        vm.prank(buyer);
        vm.expectRevert(BoraMarketplace.NotStaked.selector);
        marketplace.purchaseListing(listingId);
    }

    /*//////////////////////////////////////////////////////////////
                        COMPLETION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CompleteSale_Success() public {
        // Setup: Create, stake, purchase
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");
        
        vm.prank(validator);
        marketplace.stakeListing(listingId);
        
        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        // Fast forward past 72-hour window
        vm.warp(block.timestamp + 72 hours + 1);

        uint256 sellerBalanceBefore = usdc.balanceOf(seller);
        uint256 validatorBalanceBefore = usdc.balanceOf(validator);
        uint256 treasuryBalanceBefore = usdc.balanceOf(treasury);

        // Complete sale
        marketplace.completeSale(listingId);

        // Calculate expected payouts
        uint256 validatorCommission = (300e6 * 100) / 10_000;  // 1.0%
        uint256 platformFee = (300e6 * 150) / 10_000;          // 1.5%
        uint256 sellerPayout = 300e6 - validatorCommission - platformFee;

        // Verify payouts
        assertEq(usdc.balanceOf(seller), sellerBalanceBefore + sellerPayout);
        assertEq(usdc.balanceOf(validator), validatorBalanceBefore + validatorCommission);
        assertEq(usdc.balanceOf(treasury), treasuryBalanceBefore + platformFee);

        // Verify listing completed
        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertTrue(uint8(listing.status) == 3); // COMPLETED
    }

    function test_CompleteSale_TooEarly() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");
        
        vm.prank(validator);
        marketplace.stakeListing(listingId);
        
        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        // Try to complete immediately
        vm.expectRevert(BoraMarketplace.TooEarlyToComplete.selector);
        marketplace.completeSale(listingId);

        // Try after 24 hours (still too early)
        vm.warp(block.timestamp + 24 hours);
        vm.expectRevert(BoraMarketplace.TooEarlyToComplete.selector);
        marketplace.completeSale(listingId);
    }

    /*//////////////////////////////////////////////////////////////
                         CANCELLATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CancelListing_Success() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");

        vm.prank(seller);
        marketplace.cancelListing(listingId);

        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertTrue(uint8(listing.status) == 5); // CANCELLED
    }

    function test_CancelListing_NotSeller() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");

        vm.prank(buyer);
        vm.expectRevert(BoraMarketplace.Unauthorized.selector);
        marketplace.cancelListing(listingId);
    }

    function test_CancelListing_AlreadyStaked() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");
        
        vm.prank(validator);
        marketplace.stakeListing(listingId);

        vm.prank(seller);
        vm.expectRevert(BoraMarketplace.InvalidStatus.selector);
        marketplace.cancelListing(listingId);
    }

    /*//////////////////////////////////////////////////////////////
                          DISPUTE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InitiateDispute_Success() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");
        
        vm.prank(validator);
        marketplace.stakeListing(listingId);
        
        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        vm.prank(buyer);
        marketplace.initiateDispute(listingId, "QmEvidence456");

        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertTrue(uint8(listing.status) == 4); // DISPUTED
    }

    function test_InitiateDispute_NotBuyer() public {
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(300e6, "QmTest123");
        
        vm.prank(validator);
        marketplace.stakeListing(listingId);
        
        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        vm.prank(seller);
        vm.expectRevert(BoraMarketplace.Unauthorized.selector);
        marketplace.initiateDispute(listingId, "QmEvidence456");
    }

    /*//////////////////////////////////////////////////////////////
                      FULL FLOW INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FullFlow_HappyPath() public {
        // 1. Seller creates listing
        vm.prank(seller);
        uint256 listingId = marketplace.createListing(500e6, "QmCamera123");

        // 2. Validator stakes
        vm.prank(validator);
        marketplace.stakeListing(listingId);

        // 3. Buyer purchases
        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        // 4. Wait 72 hours
        vm.warp(block.timestamp + 72 hours + 1);

        uint256 sellerBefore = usdc.balanceOf(seller);
        uint256 validatorBefore = usdc.balanceOf(validator);

        // 5. Complete sale
        marketplace.completeSale(listingId);

        // 6. Verify all parties paid
        assertTrue(usdc.balanceOf(seller) > sellerBefore);
        assertTrue(usdc.balanceOf(validator) > validatorBefore);
        assertTrue(usdc.balanceOf(treasury) > 0);
    }

    function test_FullFlow_MultipleListings() public {
        // Validator stakes on 3 different listings
        for (uint256 i = 1; i <= 3; i++) {
            vm.prank(seller);
            uint256 listingId = marketplace.createListing(100e6 * i, "QmTest");
            
            vm.prank(validator);
            marketplace.stakeListing(listingId);
        }

        uint256[] memory validatorListings = marketplace.getValidatorListings(validator);
        assertEq(validatorListings.length, 3);
    }

    /*//////////////////////////////////////////////////////////////
                         VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetSellerListings() public {
        vm.startPrank(seller);
        marketplace.createListing(100e6, "Qm1");
        marketplace.createListing(200e6, "Qm2");
        marketplace.createListing(300e6, "Qm3");
        vm.stopPrank();

        uint256[] memory listings = marketplace.getSellerListings(seller);
        assertEq(listings.length, 3);
        assertEq(listings[0], 1);
        assertEq(listings[1], 2);
        assertEq(listings[2], 3);
    }

    function test_GetBuyerPurchases() public {
        // Create and stake 2 listings
        vm.prank(seller);
        uint256 listing1 = marketplace.createListing(100e6, "Qm1");
        vm.prank(validator);
        marketplace.stakeListing(listing1);

        vm.prank(seller);
        uint256 listing2 = marketplace.createListing(200e6, "Qm2");
        vm.prank(validator);
        marketplace.stakeListing(listing2);

        // Buyer purchases both
        vm.startPrank(buyer);
        marketplace.purchaseListing(listing1);
        marketplace.purchaseListing(listing2);
        vm.stopPrank();

        uint256[] memory purchases = marketplace.getBuyerPurchases(buyer);
        assertEq(purchases.length, 2);
    }
}
