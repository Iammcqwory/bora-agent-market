// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {BoraMarketplace} from "../src/BoraMarketplace.sol";
import {BoraStaking} from "../src/BoraStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract BoraMarketplaceFuzzTest is Test {
    BoraMarketplace public marketplace;
    BoraStaking public staking;
    ERC20Mock public usdc;

    address public owner = address(1);
    address public treasury = address(2);
    address public insurancePool = address(3);
    address public seller = address(4);
    address public validator = address(5);
    address public buyer = address(6);

    uint256 internal constant BASIS_POINTS = 10_000;
    uint256 internal constant VALIDATOR_COMMISSION_BPS = 100;
    uint256 internal constant PLATFORM_FEE_BPS = 150;
    uint256 internal constant MAX_ITEM_PRICE = 50_000e6;

    function setUp() public {
        usdc = new ERC20Mock();

        vm.prank(owner);
        staking = new BoraStaking(address(usdc), insurancePool);

        vm.prank(owner);
        marketplace = new BoraMarketplace(address(usdc), address(staking), treasury);

        vm.prank(owner);
        staking.setMarketplaceContract(address(marketplace));

        usdc.mint(seller, 100_000e6);
        usdc.mint(validator, 100_000e6);
        usdc.mint(buyer, 100_000e6);

        vm.prank(validator);
        usdc.approve(address(staking), type(uint256).max);

        vm.prank(buyer);
        usdc.approve(address(marketplace), type(uint256).max);
    }

    function testFuzz_CompleteSaleDistributesEscrowExactly(uint256 itemPrice) public {
        itemPrice = bound(itemPrice, 1, MAX_ITEM_PRICE);

        vm.prank(seller);
        uint256 listingId = marketplace.createListing(itemPrice, "QmFuzzListing");

        vm.prank(validator);
        marketplace.stakeListing(listingId);

        uint256 requiredStake = staking.getRequiredStake(itemPrice);

        vm.prank(buyer);
        marketplace.purchaseListing(listingId);

        uint256 sellerBefore = usdc.balanceOf(seller);
        uint256 validatorBefore = usdc.balanceOf(validator);
        uint256 treasuryBefore = usdc.balanceOf(treasury);
        uint256 marketplaceEscrowBefore = usdc.balanceOf(address(marketplace));
        uint256 stakingBalanceBefore = usdc.balanceOf(address(staking));

        vm.warp(block.timestamp + 72 hours + 1);
        marketplace.completeSale(listingId);

        uint256 validatorCommission = (itemPrice * VALIDATOR_COMMISSION_BPS) / BASIS_POINTS;
        uint256 platformFee = (itemPrice * PLATFORM_FEE_BPS) / BASIS_POINTS;
        uint256 sellerPayout = itemPrice - validatorCommission - platformFee;

        assertEq(marketplaceEscrowBefore, itemPrice);
        assertEq(usdc.balanceOf(address(marketplace)), 0);
        assertEq(usdc.balanceOf(seller), sellerBefore + sellerPayout);
        assertEq(usdc.balanceOf(validator), validatorBefore + requiredStake + validatorCommission);
        assertEq(usdc.balanceOf(treasury), treasuryBefore + platformFee);
        assertEq(stakingBalanceBefore, requiredStake);
        assertEq(usdc.balanceOf(address(staking)), 0);
        assertEq(sellerPayout + validatorCommission + platformFee, itemPrice);

        BoraMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(uint8(listing.status), uint8(BoraMarketplace.ListingStatus.COMPLETED));
    }
}
