// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {BoraStaking} from "../src/BoraStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract BoraStakingFuzzTest is Test {
    BoraStaking public staking;
    ERC20Mock public usdc;

    address public owner = address(1);
    address public marketplace = address(2);
    address public dispute = address(3);
    address public insurancePool = address(4);
    address public validator = address(5);
    address public beneficiary = address(6);

    uint256 internal constant BASIS_POINTS = 10_000;
    uint256 internal constant PREMIUM_BPS = 200;
    uint256 internal constant MAX_ITEM_PRICE = 10_000e6;

    function setUp() public {
        usdc = new ERC20Mock();

        vm.prank(owner);
        staking = new BoraStaking(address(usdc), insurancePool);

        vm.startPrank(owner);
        staking.setMarketplaceContract(marketplace);
        staking.setDisputeContract(dispute);
        vm.stopPrank();

        usdc.mint(validator, 20_000e6);

        vm.prank(validator);
        usdc.approve(address(staking), type(uint256).max);
    }

    function testFuzz_GetRequiredStakeMatchesTierSchedule(uint256 itemPrice) public view {
        itemPrice = bound(itemPrice, 1, MAX_ITEM_PRICE);

        uint256 expectedStake;
        if (itemPrice < 100e6) {
            expectedStake = (itemPrice * 2_000) / BASIS_POINTS;
        } else if (itemPrice < 500e6) {
            expectedStake = (itemPrice * 3_500) / BASIS_POINTS;
        } else if (itemPrice < 1_000e6) {
            expectedStake = (itemPrice * 5_000) / BASIS_POINTS;
        } else {
            expectedStake = (itemPrice * 7_500) / BASIS_POINTS;
        }

        assertEq(staking.getRequiredStake(itemPrice), expectedStake);
    }

    function testFuzz_LockStakeTracksExposure(uint256 listingId, uint256 itemPrice) public {
        itemPrice = bound(itemPrice, 1, MAX_ITEM_PRICE);
        listingId = bound(listingId, 1, type(uint32).max);

        uint256 requiredStake = staking.getRequiredStake(itemPrice);
        uint256 premium = (requiredStake * PREMIUM_BPS) / BASIS_POINTS;
        uint256 validatorBalanceBefore = usdc.balanceOf(validator);
        uint256 poolBalanceBefore = usdc.balanceOf(insurancePool);

        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator, listingId, itemPrice);

        BoraStaking.Stake memory stake = staking.getStake(stakeId);

        assertEq(stake.validator, validator);
        assertEq(stake.listingId, listingId);
        assertEq(stake.amount, requiredStake);
        assertEq(uint8(stake.status), uint8(BoraStaking.StakeStatus.LOCKED));
        assertEq(staking.validatorTotalStaked(validator), requiredStake);
        assertEq(usdc.balanceOf(validator), validatorBalanceBefore - requiredStake - premium);
        assertEq(usdc.balanceOf(insurancePool), poolBalanceBefore + premium);

        uint256[] memory validatorStakeIds = staking.getValidatorStakes(validator);
        assertEq(validatorStakeIds.length, 1);
        assertEq(validatorStakeIds[0], stakeId);
    }

    function testFuzz_ReleaseStakeRestoresValidatorBalance(uint256 listingId, uint256 itemPrice) public {
        itemPrice = bound(itemPrice, 1, MAX_ITEM_PRICE);
        listingId = bound(listingId, 1, type(uint32).max);

        uint256 requiredStake = staking.getRequiredStake(itemPrice);
        uint256 premium = (requiredStake * PREMIUM_BPS) / BASIS_POINTS;

        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator, listingId, itemPrice);

        uint256 validatorBalanceAfterLock = usdc.balanceOf(validator);

        vm.warp(block.timestamp + 72 hours + 1);

        vm.prank(marketplace);
        staking.releaseStake(stakeId);

        BoraStaking.Stake memory stake = staking.getStake(stakeId);

        assertEq(uint8(stake.status), uint8(BoraStaking.StakeStatus.RELEASED));
        assertEq(staking.validatorTotalStaked(validator), 0);
        assertEq(usdc.balanceOf(validator), validatorBalanceAfterLock + requiredStake);
        assertEq(usdc.balanceOf(validator), 20_000e6 - premium);
    }

    function testFuzz_SlashStakeTransfersLockedAmount(uint256 listingId, uint256 itemPrice) public {
        itemPrice = bound(itemPrice, 1, MAX_ITEM_PRICE);
        listingId = bound(listingId, 1, type(uint32).max);

        uint256 requiredStake = staking.getRequiredStake(itemPrice);
        uint256 beneficiaryBalanceBefore = usdc.balanceOf(beneficiary);

        vm.prank(marketplace);
        uint256 stakeId = staking.lockStake(validator, listingId, itemPrice);

        vm.prank(dispute);
        staking.slashStake(stakeId, beneficiary);

        BoraStaking.Stake memory stake = staking.getStake(stakeId);

        assertEq(uint8(stake.status), uint8(BoraStaking.StakeStatus.SLASHED));
        assertEq(staking.validatorTotalStaked(validator), 0);
        assertEq(usdc.balanceOf(beneficiary), beneficiaryBalanceBefore + requiredStake);
    }
}
